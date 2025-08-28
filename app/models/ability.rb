class Ability
  include CanCan::Ability

  def initialize user
    user ||= User.new

    if user.trainee?
      define_trainee_abilities(user)
      can :access, :trainee
    elsif user.supervisor?
      define_supervisor_abilities(user)
      can :access, :supervisor
    elsif user.admin?
      can :manage, :all
      can :access, :admin
    else
      # guest
      cannot :manage, :all
    end
  end

  private

  def define_trainee_abilities current_user
    define_trainee_course_abilities(current_user)
    define_trainee_subject_abilities(current_user)
    define_trainee_user_abilities(current_user)
    define_trainee_report_abilities(current_user)
    define_trainee_comment_abilities(current_user)
  end

  def define_trainee_course_abilities current_user
    # Courses: read only courses that user has joined
    can :read, Course, users: {id: current_user.id}

    # Course members/subjects pages (custom actions): allow if member
    can :members, Course do |course|
      course.users.exists?(id: current_user.id)
    end
    can :subjects, Course do |course|
      course.users.exists?(id: current_user.id)
    end
  end

  def define_trainee_subject_abilities current_user
    # Subjects (show in course context): allow if enrolled in course
    can :show, Subject do |subject|
      CourseSubject.joins(:course)
                   .where(subject_id: subject.id,
                          courses: {id: current_user.course_ids})
                   .exists?
    end
  end

  def define_trainee_user_abilities current_user
    # UserCourse: read/comment only own user_course
    can :read, UserCourse, user_id: current_user.id

    # UserSubject: update own status
    can :update, UserSubject, user_id: current_user.id

    # UserTask: update documents, status, time spent for own tasks
    can :update, UserTask, user_id: current_user.id
  end

  def define_trainee_report_abilities current_user
    # DailyReport: CRUD on own reports (draft + submitted read)
    can :read, DailyReport, user_id: current_user.id
    can %i(create update destroy), DailyReport, user_id: current_user.id
  end

  def define_trainee_comment_abilities current_user
    # Comment: create on entities belonging to self (user_course, user_subject)
    can :create, Comment do |comment|
      case comment.commentable
      when UserCourse
        comment.commentable.user_id == current_user.id
      when UserSubject
        comment.commentable.user_id == current_user.id
      else
        false
      end
    end
    can :read, Comment, user_id: current_user.id
  end

  def define_supervisor_abilities current_user
    define_supervisor_course_abilities(current_user)
    define_supervisor_user_management_abilities(current_user)
    define_supervisor_learning_structure_abilities(current_user)
  end

  def define_supervisor_course_abilities current_user
    # Supervisor permissions are stronger than trainee on managed courses
    # Allow access to supervisor namespaces
    can :read, Course, supervisors: {id: current_user.id}
    define_supervisor_user_course_abilities(current_user)
    define_supervisor_user_subject_abilities(current_user)
    define_supervisor_user_task_abilities(current_user)
    define_supervisor_daily_report_abilities(current_user)
    define_supervisor_comment_abilities(current_user)
    define_supervisor_course_subject_abilities(current_user)
  end

  def define_supervisor_user_course_abilities current_user
    can :manage, UserCourse do |user_course|
      user_course.course.supervisors.exists?(id: current_user.id)
    end
  end

  def define_supervisor_user_subject_abilities current_user
    can :manage, UserSubject do |user_subject|
      course = user_subject.course_subject&.course
      course&.supervisors&.exists?(id: current_user.id)
    end
  end

  def define_supervisor_user_task_abilities current_user
    can :manage, UserTask do |user_task|
      course = user_task.user_subject&.course_subject&.course
      course&.supervisors&.exists?(id: current_user.id)
    end
  end

  def define_supervisor_daily_report_abilities current_user
    can :manage, DailyReport do |report|
      report.course.supervisors.exists?(id: current_user.id)
    end
  end

  def define_supervisor_comment_abilities current_user
    can :manage, Comment do |comment|
      case comment.commentable
      when UserCourse
        comment.commentable.course.supervisors.exists?(id: current_user.id)
      when UserSubject
        course = comment.commentable.course_subject&.course
        course&.supervisors&.exists?(id: current_user.id)
      else
        false
      end
    end
  end

  def define_supervisor_course_subject_abilities current_user
    # Manage CourseSubject in supervised courses
    can :manage, CourseSubject do |course_subject|
      course_subject.course.supervisors.exists?(id: current_user.id)
    end
  end

  def define_supervisor_user_management_abilities current_user
    # Manage trainees in courses supervised by current supervisor
    can :manage, User do |user|
      next false unless user.trainee?

      # trainee has at least one course managed by current supervisor
      (user.course_ids & current_user.supervised_courses.pluck(:id)).any?
    end
  end

  def define_supervisor_learning_structure_abilities _current_user
    # Manage learning structure
    can :manage, Subject
    can :manage, Task
    can :manage, Category
  end
end
