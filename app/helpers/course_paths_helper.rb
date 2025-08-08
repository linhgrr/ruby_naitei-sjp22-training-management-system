module CoursePathsHelper
  def course_link_url_for course
    if admin_role? || supervisor_role?
      supervisor_course_url(course)
    else
      trainee_course_url(course)
    end
  end

  def course_members_path_for course
    if admin_role? || supervisor_role?
      members_supervisor_course_path(course)
    else
      members_trainee_course_path(course)
    end
  end

  def course_subjects_path_for course
    if admin_role? || supervisor_role?
      subjects_supervisor_course_path(course)
    else
      subjects_trainee_course_path(course)
    end
  end

  def destroy_user_course_path_for course, user_course_id:
    supervisor_course_user_course_path(course, id: user_course_id)
  end

  def destroy_supervisor_path_for course, supervisor_id:
    supervisor_course_supervisor_path(course, id: supervisor_id)
  end

  def finish_course_subject_path_for course, course_subject_id:
    finish_supervisor_course_course_subject_path(course, id: course_subject_id)
  end

  def destroy_course_subject_path_for course, course_subject_id:
    supervisor_course_course_subject_path(course, id: course_subject_id)
  end

  def leave_course_path_for course
    leave_supervisor_course_path(course)
  end

  def course_edit_path_for course
    edit_supervisor_course_path(course)
  end

  def can_edit_course? course
    return false unless current_user

    current_user.admin? ||
      (current_user.supervisor? && course.supervisors.include?(current_user))
  end

  def add_subject_path_for course
    add_subject_supervisor_course_path(course)
  end
end
