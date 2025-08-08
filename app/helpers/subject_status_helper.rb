module SubjectStatusHelper
  def subject_status course_subject
    return Settings.subject_status.finished if subject_finished?(course_subject)
    if subject_in_progress?(course_subject)
      return Settings.subject_status.in_progress
    end

    Settings.subject_status.not_started
  end

  private

  def subject_finished? course_subject
    past_finish_date?(course_subject) || all_trainees_finished?(course_subject)
  end

  def subject_in_progress? course_subject
    course_subject.start_date && course_subject.start_date <= Date.current
  end

  def past_finish_date? course_subject
    course_subject.finish_date && course_subject.finish_date < Date.current
  end

  def all_trainees_finished? course_subject
    return false unless course_subject.association(:user_subjects).loaded?

    finished_status_values = UserSubject.statuses.values_at(
      :finished_early, :finished_ontime, :finished_but_overdue
    )

    course_subject.user_subjects.all? do |user_subject|
      finished_status_values.include?(user_subject.status_before_type_cast)
    end
  end
end
