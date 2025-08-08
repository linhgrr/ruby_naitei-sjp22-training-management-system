import "jquery"
import "jquery-ui"

document.addEventListener('DOMContentLoaded', function() {
  initializeCourseEdit();
  initializeSubjectSearch();
});

document.addEventListener('turbo:load', function() {
  initializeCourseEdit();
  initializeSubjectSearch();
});

function initializeCourseEdit() {
  // Skip if not on course edit page
  if (!document.querySelector('.course-edit-page')) return;

  // Initialize sortable subjects
  initializeSortableSubjects();
  
  // Initialize task management
  initializeTaskManagement();
}

function initializeSortableSubjects() {
  const $ = window.jQuery;
  if (!$ || !$.ui) return;

  $('#sortable-subjects').sortable({
    handle: '.subject-drag-handle',
    placeholder: 'subject-placeholder',
    helper: 'clone',
    opacity: 0.8,
    cursor: 'move',
    tolerance: 'pointer',
    update: function(event, ui) {
      // Update position inputs and names when order changes
      $('#sortable-subjects .subject-edit-card').each(function(index) {
        const $card = $(this);
        
        // Update position value and label
        $card.find('.position-input').val(index + 1);
        $card.find('.position-label').text('[' + (index + 1) + ']');
        
        // Update input names with new index
        $card.find('input[name*="course_subjects_attributes"]').each(function() {
          const name = $(this).attr('name');
          // Replace the first occurrence of [number] with new index
          const newName = name.replace(/\[(\d+)\]/, '[' + index + ']');
          $(this).attr('name', newName);
        });
      });
    },
    start: function(event, ui) {
      ui.helper.addClass('ui-sortable-helper');
    },
    stop: function(event, ui) {
      ui.item.removeClass('ui-sortable-helper');
    }
  });

  // Add placeholder styles
  const style = document.createElement('style');
  style.textContent = `
    .subject-placeholder {
      height: 100px;
      background: #f8f9fa;
      border: 2px dashed #dee2e6;
      border-radius: 8px;
      margin-bottom: 15px;
      display: flex;
      align-items: center;
      justify-content: center;
      color: #6c757d;
      font-style: italic;
    }
    .subject-placeholder:before {
      content: "Drop subject here";
    }
    .ui-sortable-helper {
      box-shadow: 0 4px 16px rgba(0,0,0,0.2) !important;
      transform: rotate(2deg) !important;
      z-index: 1000;
    }
  `;
  document.head.appendChild(style);
}

function initializeTaskManagement() {
  // Toggle task form visibility
  document.querySelectorAll('.toggle-task-form').forEach(button => {
    button.addEventListener('click', function() {
      const subjectId = this.dataset.subjectId;
      const form = document.getElementById(`tasks-form-${subjectId}`);
      
      if (form.style.display === 'none' || form.style.display === '') {
        form.style.display = 'block';
        this.innerHTML = '<i class="fas fa-eye-slash"></i> Hide';
        this.classList.remove('btn-outline-success');
        this.classList.add('btn-outline-secondary');
      } else {
        form.style.display = 'none';
        this.innerHTML = '<i class="fas fa-plus"></i> Fill more tasks';
        this.classList.remove('btn-outline-secondary');
        this.classList.add('btn-outline-success');
      }
    });
  });

  // Add new task functionality
  document.querySelectorAll('.add-new-task').forEach(button => {
    button.addEventListener('click', function() {
      const subjectId = this.dataset.subjectId;
      const container = this.closest('.new-tasks-form').querySelector('.new-tasks-list');
      const template = this.closest('.new-tasks-form').querySelector('.new-task-template');
      
      if (!template) return;
      
      const newTask = template.cloneNode(true);
      newTask.style.display = 'block';
      newTask.classList.remove('new-task-template');
      newTask.classList.add('new-task-item-active');
      
      // Update input names to be unique
      const timestamp = Date.now();
      const inputs = newTask.querySelectorAll('input');
      inputs.forEach(input => {
        const name = input.getAttribute('name');
        if (name) {
          const newName = name.replace('NEW_TASK_INDEX', timestamp);
          input.setAttribute('name', newName);
        }
        input.removeAttribute('disabled');
      });
      
      container.appendChild(newTask);
      
      // Focus on the first input
      const firstInput = newTask.querySelector('input[type="text"]');
      if (firstInput) {
        firstInput.focus();
      }
      
      // Add remove functionality to the new task
      const removeButton = newTask.querySelector('.remove-task');
      if (removeButton) {
        removeButton.addEventListener('click', function() {
          newTask.remove();
        });
      }
    });
  });

  // Remove task functionality for existing remove buttons
  document.querySelectorAll('.remove-task').forEach(button => {
    button.addEventListener('click', function() {
      this.closest('.new-task-item, .new-task-item-active').remove();
    });
  });
}

// Subject search functionality
function initializeSubjectSearch() {
  const searchInput = document.getElementById('subject-search-input');
  const searchResults = document.getElementById('subject-search-results');
  
  if (!searchInput || !searchResults) return;
  
  let searchTimeout;
  
  searchInput.addEventListener('input', function() {
    const query = this.value.trim();
    
    // Clear previous timeout
    clearTimeout(searchTimeout);
    
    if (query.length < 2) {
      searchResults.innerHTML = '';
      searchResults.style.display = 'none';
      return;
    }
    
    // Debounce search
    searchTimeout = setTimeout(() => {
      performSearch(query, searchInput, searchResults);
    }, 300);
  });
  
  // Hide results when clicking outside
  document.addEventListener('click', function(e) {
    if (!searchInput.contains(e.target) && !searchResults.contains(e.target)) {
      searchResults.style.display = 'none';
    }
  });
}

function performSearch(query, searchInput, searchResults) {
  const searchUrl = searchInput.dataset.searchUrl;
  const addUrl = searchInput.dataset.addUrl;
  const courseId = getCourseIdFromUrl();
  
  if (!searchUrl || !addUrl) {
    console.error('Missing search or add URL');
    return;
  }
  
  // Show loading
  searchResults.innerHTML = '<div class="list-group-item">Searching...</div>';
  searchResults.style.display = 'block';
  
  // Get CSRF token
  const token = document.querySelector('meta[name="csrf-token"]')?.getAttribute('content');
  
  fetch(`${searchUrl}?query=${encodeURIComponent(query)}&course_id=${courseId}`, {
    headers: {
      'Accept': 'application/json',
      'X-CSRF-Token': token
    }
  })
  .then(response => response.json())
  .then(subjects => {
    displaySearchResults(subjects, searchResults, addUrl, token);
  })
  .catch(error => {
    console.error('Search error:', error);
    searchResults.innerHTML = '<div class="list-group-item text-danger">Error occurred during search</div>';
  });
}

function displaySearchResults(subjects, searchResults, addUrl, token) {
  if (subjects.length === 0) {
    searchResults.innerHTML = '<div class="list-group-item">No subjects found</div>';
    return;
  }
  
  const resultsHtml = subjects.map(subject => {
    const tasksDisplay = subject.tasks && subject.tasks.length > 0 ? 
      `<div class="mt-2">
        <small class="text-muted d-block"><strong>Tasks (${subject.tasks.length}):</strong></small>
        ${subject.tasks.map(task => `
          <small class="d-block text-muted ml-2">• ${escapeHtml(task.name)}${task.description ? ': ' + escapeHtml(task.description) : ''}</small>
        `).join('')}
      </div>` : 
      '<small class="text-muted d-block">No tasks defined</small>';
    
    return `
      <div class="list-group-item list-group-item-action subject-search-result" 
           data-subject-id="${subject.id}">
        <div class="d-flex justify-content-between align-items-start">
          <div class="flex-grow-1">
            <h6 class="mb-1">${escapeHtml(subject.name)}</h6>
            <small class="text-muted">${subject.estimated_time_days} days • Max score: ${subject.max_score}</small>
            ${tasksDisplay}
          </div>
          <button class="btn btn-sm btn-outline-primary add-subject-btn ml-3" 
                  data-subject-id="${subject.id}">Add</button>
        </div>
      </div>
    `;
  }).join('');
  
  searchResults.innerHTML = resultsHtml;
  
  // Add click handlers for add buttons
  searchResults.querySelectorAll('.add-subject-btn').forEach(btn => {
    btn.addEventListener('click', function(e) {
      e.stopPropagation();
      const subjectId = this.dataset.subjectId;
      addSubjectToCourse(subjectId, addUrl, token, this);
    });
  });
}

function addSubjectToCourse(subjectId, addUrl, token, button) {
  // Show loading state
  button.disabled = true;
  button.textContent = 'Adding...';
  
  fetch(addUrl, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'X-CSRF-Token': token,
      'Accept': 'application/json'
    },
    body: JSON.stringify({ subject_id: subjectId })
  })
  .then(response => response.json())
  .then(data => {
    if (data.success) {
      // Show success message
      showNotification(data.message || 'Subject added successfully', 'success');
      
      // Hide search results
      document.getElementById('subject-search-results').style.display = 'none';
      document.getElementById('subject-search-input').value = '';
      
      // Reload page to show new subject
      setTimeout(() => {
        window.location.reload();
      }, 1000);
    } else {
      showNotification(data.message || 'Failed to add subject', 'error');
      button.disabled = false;
      button.textContent = 'Add';
    }
  })
  .catch(error => {
    console.error('Add subject error:', error);
    showNotification('Error occurred while adding subject', 'error');
    button.disabled = false;
    button.textContent = 'Add';
  });
}

function getCourseIdFromUrl() {
  const pathParts = window.location.pathname.split('/');
  const courseIndex = pathParts.findIndex(part => part === 'courses');
  return courseIndex !== -1 && pathParts[courseIndex + 1] ? pathParts[courseIndex + 1] : '';
}

function escapeHtml(text) {
  const div = document.createElement('div');
  div.textContent = text;
  return div.innerHTML;
}

function showNotification(message, type) {
  // Simple notification - can be enhanced with a proper notification system
  const notification = document.createElement('div');
  notification.className = `alert alert-${type === 'success' ? 'success' : 'danger'} alert-dismissible fade show`;
  notification.style.position = 'fixed';
  notification.style.top = '20px';
  notification.style.right = '20px';
  notification.style.zIndex = '9999';
  notification.innerHTML = `
    ${message}
    <button type="button" class="close" data-dismiss="alert">
      <span>&times;</span>
    </button>
  `;
  
  document.body.appendChild(notification);
  
  // Auto remove after 3 seconds
  setTimeout(() => {
    notification.remove();
  }, 3000);
}

// Export for use in inline scripts
window.initializeCourseEdit = initializeCourseEdit;


