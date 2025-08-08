class Supervisor::CoursesController < Supervisor::BaseController
  include Supervisor::CoursesHelper

  EAGER_LOAD_SUBJECTS = [
    :subject,
    :tasks,
    {user_subjects: [:user, :comments]}
  ].freeze

  before_action :load_course,
                only: %i(show members subjects supervisors leave edit update
add_subject)
  before_action :authorize_supervisor_access!, except: [:index]
  before_action :ensure_multiple_supervisors, only: [:leave]
  before_action :set_courses_page_class
  before_action :check_supervisor_role

  # GET /supervisor/courses
  def index
    @statuses = build_statuses

    courses_query = accessible_courses
                    .includes(:user)
                    .with_counts
                    .filter_by_params(params)
                    .ordered_by_start_date

    @pagy, @courses = pagy courses_query, limit: Settings.ui.items_per_page
  end

  # GET /supervisor/courses/:id
  def show
    redirect_to subjects_supervisor_course_path @course
  end

  # GET /supervisor/courses/:id/members
  def members
    @trainers = @course.supervisors.includes :user_courses
    @pagy, @trainees = pagy(
      @course.user_courses.trainees.includes(:user),
      limit: Settings.pagination.course_members_per_page
    )
    @trainee_count = @pagy.count
    @trainer_count = @trainers.count
    @subject_count = @course.subjects.count

    render template: Settings.templates.courses.members
  end

  # GET /supervisor/courses/:id/subjects
  def subjects
    @subjects = @course.course_subjects.includes(EAGER_LOAD_SUBJECTS)
                       .ordered_by_position
    @subject_count = @subjects.count
    @trainee_count = @course.trainees_count
    @trainer_count = @course.supervisors.count

    render template: Settings.templates.courses.subjects
  end

  # GET /supervisor/courses/:id/supervisors
  def supervisors
    @trainers = @course.supervisors.includes :user_courses
    @trainer_count = @trainers.count
    @subject_count = @course.subjects.count
    @trainee_count = @course.trainees_count
  end

  # POST supervisor/courses
  def create
    @course = Course.new course_params.merge(user_id: current_user.id)

    if @course.save
      flash[:success] = t(".course_created_successfully")
      redirect_to supervisor_courses_path
    else
      flash[:danger] = t(".course_creation_failed")
      render :new, status: :unprocessable_entity
    end
  end

  # DELETE /supervisor/courses/:id/leave
  def leave
    if @course.supervisors.destroy(current_user)
      flash[:success] = t(".success")
      redirect_to supervisor_courses_path
    else
      flash[:danger] = t(".failed")
      redirect_back fallback_location: members_fallback_path
    end
  end

  # GET supervisor/courses/new
  def new
    @course = Course.new
    @course.course_subjects.build.build_subject
  end

  # GET /supervisor/courses/:id/edit
  def edit
    @subjects = @course.course_subjects.includes(:subject, :tasks)
                       .ordered_by_position
    render template: "courses/edit"
  end

  # PATCH /supervisor/courses/:id
  def update
    if @course.update(course_params)
      flash[:success] = t(".course_updated_successfully")
      redirect_to subjects_supervisor_course_path(@course)
    else
      @course.reload
      @subjects = @course.course_subjects.includes(:subject, :tasks)
                         .ordered_by_position
      flash[:danger] = t(".course_update_failed")
      render template: "courses/edit", status: :unprocessable_entity
    end
  end

  # POST /supervisor/courses/:id/add_subject
  def add_subject
    subject_id = params[:subject_id]
    subject = Subject.find_by(id: subject_id)

    unless subject
      render json: {
        success: false,
        message: t(".subject_not_found")
      }, status: :not_found
      return
    end

    # Check if subject is already in course
    if @course.subjects.include?(subject)
      render json: {
        success: false,
        message: t(".subject_already_added")
      }, status: :unprocessable_entity
      return
    end

    # Add subject to course with next position
    next_position = @course.course_subjects.maximum(:position).to_i + 1
    course_subject = @course.course_subjects.build(
      subject: subject,
      position: next_position
    )

    if course_subject.save
      copy_subject_tasks_to_course_subject(subject, course_subject)

      render json: {
        success: true,
        message: t(".subject_added_successfully", subject_name: subject.name)
      }
    else
      render json: {
        success: false,
        message: t(".failed_to_add_subject")
      }, status: :unprocessable_entity
    end
  end

  private

  def copy_subject_tasks_to_course_subject subject, course_subject
    subject.tasks.each do |subject_task|
      course_subject.tasks.create!(
        name: subject_task.name
      )
    end
  end

  def course_params
    params.require(:course).permit Course::COURSE_PARAMS
  end

  def accessible_courses
    if current_user&.admin?
      Course.all
    else
      Course.where(
        "courses.user_id = ? OR courses.id IN (
          SELECT course_id FROM course_supervisors WHERE user_id = ?
        )",
        current_user.id, current_user.id
      )
    end
  end

  def load_course
    @course = Course.includes(course_subjects: [:subject, :tasks,
:user_subjects])
                    .find_by(id: params[:id])
    return if @course

    flash[:danger] = I18n.t("courses.errors.course_not_found")
    redirect_to root_path
  end

  def authorize_supervisor_access!
    return if current_user&.admin?

    return if allowed_for_supervisor?(@course)

    flash[:danger] = I18n.t("courses.errors.access_denied")
    redirect_to root_path
  end

  def allowed_for_supervisor? course
    return false unless course

    if read_only_action?
      course.user_id == current_user&.id ||
        course.supervisors.include?(current_user)
    else
      course.supervisors.include?(current_user)
    end
  end

  def read_only_action?
    %w(show members subjects).include?(action_name)
  end

  def set_courses_page_class
    self.page_class = if current_user&.admin?
                        Settings.page_classes.admin_courses
                      else
                        Settings.page_classes.courses
                      end
  end

  def ensure_multiple_supervisors
    return if @course.supervisors.count > 1

    flash[:danger] = t("courses.leave.must_have_another_supervisor")
    redirect_back fallback_location: members_fallback_path
  end

  def members_fallback_path
    members_supervisor_course_path(@course)
  end

  def subjects_fallback_path
    subjects_supervisor_course_path(@course)
  end
end
