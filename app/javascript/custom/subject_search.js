document.addEventListener('DOMContentLoaded', function() {
  initSubjectSearch();
});

document.addEventListener('turbo:load', function() {
  initSubjectSearch();
});

function initSubjectSearch() {
  const searchInput = document.getElementById('subject-search-input');
  const resultsContainer = document.getElementById('subject-search-results');
  
  if (!searchInput || !resultsContainer) return;

  let debounceTimer;
  const DEBOUNCE_DELAY = 300;

  // Clear results when clicking outside
  document.addEventListener('click', function(e) {
    if (!searchInput.contains(e.target) && !resultsContainer.contains(e.target)) {
      resultsContainer.innerHTML = '';
    }
  });

  // Handle search input with debounce
  searchInput.addEventListener('input', function() {
    const query = this.value.trim();
    
    clearTimeout(debounceTimer);
    
    if (query.length < 2) {
      resultsContainer.innerHTML = '';
      return;
    }

    // Show loading state
    resultsContainer.innerHTML = `
      <div class="list-group-item text-center">
        <div class="spinner-border spinner-border-sm" role="status">
          <span class="visually-hidden">Loading...</span>
        </div>
        <span class="ms-2">Searching...</span>
      </div>
    `;

    debounceTimer = setTimeout(() => {
      searchSubjects(query, searchInput, resultsContainer);
    }, DEBOUNCE_DELAY);
  });

  // Handle Enter key
  searchInput.addEventListener('keydown', function(e) {
    if (e.key === 'Enter') {
      e.preventDefault();
      const firstResult = resultsContainer.querySelector('.subject-result-item');
      if (firstResult) {
        firstResult.click();
      }
    }
  });
}

async function searchSubjects(query, searchInput, resultsContainer) {
  try {
    const searchUrl = searchInput.dataset.searchUrl;
    const courseId = getCurrentCourseId();
    
    const url = new URL(searchUrl, window.location.origin);
    url.searchParams.append('query', query);
    if (courseId) {
      url.searchParams.append('course_id', courseId);
    }

    const response = await fetch(url, {
      method: 'GET',
      headers: {
        'Accept': 'application/json',
        'X-Requested-With': 'XMLHttpRequest',
        'X-CSRF-Token': getCSRFToken()
      }
    });

    if (!response.ok) {
      throw new Error(`HTTP error! status: ${response.status}`);
    }

    const subjects = await response.json();
    displaySearchResults(subjects, resultsContainer, searchInput);

  } catch (error) {
    console.error('Error searching subjects:', error);
    resultsContainer.innerHTML = `
      <div class="list-group-item text-danger">
        <i class="fas fa-exclamation-triangle"></i>
        <span class="ms-2">Error searching subjects. Please try again.</span>
      </div>
    `;
  }
}

function displaySearchResults(subjects, resultsContainer, searchInput) {
  if (subjects.length === 0) {
    resultsContainer.innerHTML = `
      <div class="list-group-item text-muted">
        <i class="fas fa-search"></i>
        <span class="ms-2">No subjects found</span>
      </div>
    `;
    return;
  }

  const resultsHtml = subjects.map(subject => {
    const taskNames = subject.task_names || [];
    const tasksDisplay = taskNames.length > 0 
      ? `<small class="text-muted d-block">Tasks: ${taskNames.slice(0, 3).join(', ')}${taskNames.length > 3 ? '...' : ''}</small>`
      : '<small class="text-muted d-block">No tasks</small>';

    const timeDisplay = subject.estimated_time_days 
      ? `<small class="text-info">${subject.estimated_time_days} days</small>`
      : '';

    return `
      <button type="button" 
              class="list-group-item list-group-item-action subject-result-item" 
              data-subject-id="${subject.id}"
              data-add-url="${searchInput.dataset.addUrl}">
        <div class="d-flex justify-content-between align-items-start">
          <div class="flex-grow-1">
            <strong>${escapeHtml(subject.name)}</strong>
            ${tasksDisplay}
          </div>
          <div class="text-end">
            ${timeDisplay}
            <div class="mt-1">
              <i class="fas fa-plus text-success"></i>
            </div>
          </div>
        </div>
      </button>
    `;
  }).join('');

  resultsContainer.innerHTML = resultsHtml;

  // Add click handlers to results
  resultsContainer.querySelectorAll('.subject-result-item').forEach(item => {
    item.addEventListener('click', function() {
      addSubjectToCourse(this);
    });
  });
}

async function addSubjectToCourse(resultItem) {
  const subjectId = resultItem.dataset.subjectId;
  const addUrl = resultItem.dataset.addUrl;
  const subjectName = resultItem.querySelector('strong').textContent;

  // Show loading state
  resultItem.innerHTML = `
    <div class="text-center">
      <div class="spinner-border spinner-border-sm" role="status">
        <span class="visually-hidden">Adding...</span>
      </div>
      <span class="ms-2">Adding ${subjectName}...</span>
    </div>
  `;
  resultItem.disabled = true;

  try {
    const response = await fetch(addUrl, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'X-Requested-With': 'XMLHttpRequest',
        'X-CSRF-Token': getCSRFToken()
      },
      body: JSON.stringify({
        subject_id: subjectId
      })
    });

    const result = await response.json();

    if (result.success) {
      // Show success message
      showNotification(result.message, 'success');
      
      // Clear search
      const searchInput = document.getElementById('subject-search-input');
      const resultsContainer = document.getElementById('subject-search-results');
      if (searchInput) searchInput.value = '';
      if (resultsContainer) resultsContainer.innerHTML = '';
      
      // Refresh page to show new subject
      setTimeout(() => {
        window.location.reload();
      }, 1000);
      
    } else {
      showNotification(result.message, 'error');
      // Restore original content
      displaySearchResults([{
        id: subjectId,
        name: subjectName,
        task_names: [],
        estimated_time_days: null
      }], document.getElementById('subject-search-results'), document.getElementById('subject-search-input'));
    }

  } catch (error) {
    console.error('Error adding subject:', error);
    showNotification('Failed to add subject. Please try again.', 'error');
  }
}

function getCurrentCourseId() {
  // Try to get course ID from URL path
  const pathMatch = window.location.pathname.match(/\/courses\/(\d+)/);
  if (pathMatch) {
    return pathMatch[1];
  }
  
  // Try to get from data attribute
  const courseElement = document.querySelector('[data-course-id]');
  if (courseElement) {
    return courseElement.dataset.courseId;
  }
  
  return null;
}

function getCSRFToken() {
  const metaTag = document.querySelector('meta[name="csrf-token"]');
  return metaTag ? metaTag.getAttribute('content') : '';
}

function escapeHtml(text) {
  const div = document.createElement('div');
  div.textContent = text;
  return div.innerHTML;
}

function showNotification(message, type = 'info') {
  // Create notification element
  const notification = document.createElement('div');
  notification.className = `alert alert-${type === 'success' ? 'success' : type === 'error' ? 'danger' : 'info'} alert-dismissible fade show position-fixed`;
  notification.style.cssText = 'top: 20px; right: 20px; z-index: 9999; min-width: 300px;';
  
  notification.innerHTML = `
    ${message}
    <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
  `;
  
  document.body.appendChild(notification);
  
  // Auto remove after 5 seconds
  setTimeout(() => {
    if (notification.parentNode) {
      notification.remove();
    }
  }, 5000);
}

