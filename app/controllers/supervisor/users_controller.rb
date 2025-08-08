class Supervisor::UsersController < Supervisor::BaseController
  before_action :check_permissions,
                only: %i(index show update_status bulk_deactivate)
  before_action :load_courses, only: %i(index)
  before_action :load_trainees, only: %i(index)
  before_action :load_trainee, only: %i(show update_status)
  before_action :set_css_class, only: %i(index)
  before_action :require_manager
  skip_before_action :check_supervisor_role
  # GET /supervisor/users
  def index
    @pagy, @trainees = pagy(@user_trainees)
  end

  # GET /supervisor/users/:id
  def show
    @user = @user_trainee
    render template: "users/show"
  end

  # PATCH /supervisor/users/:id/update_status
  def update_status
    flash[:success] = t(".update_success") if update_status?

    redirect_to supervisor_users_path
  end

  # PATCH /supervisor/users/bulk_deactivate
  def bulk_deactivate
    handle_bulk_statuses
    redirect_to supervisor_users_path
  end

  private

  def load_trainees
    @user_trainees = User.trainee.filter_by_name(params[:search])
                         .filter_by_status(params[:status])
                         .by_course(params[:course])
                         .recent
  end

  def load_courses
    @courses = Course.recent
  end

  def load_trainee
    @user_trainee = User.find_by(id: params[:id])
    return if @user_trainee

    flash[:danger] = t(".trainee.not_found")
    redirect_to supervisor_users_path
  end

  def update_status?
    if params[:activated].present? &&
       @user_trainee.update(activated: params[:activated])
      return true
    end

    flash[:danger] = t(".update_failed")
    false
  end

  def handle_bulk_statuses
    trainee_ids = params[:trainee_ids]

    return flash_no_selection if trainee_ids.blank?

    trainees = User.where(id: trainee_ids)
    updated_count = toggle_trainees_status(trainees)

    flash_bulk_status_result(updated_count)
  end

  def flash_bulk_status_result updated_count
    if updated_count.positive?
      flash[:success] = t(".bulk_statuses_success", count: updated_count)
    else
      flash[:danger] = t(".bulk_statuses_failed")
    end
  end

  def toggle_trainees_status trainees
    updated_count = 0
    trainees.each do |trainee|
      new_status = trainee.active? ? :inactive : :active
      updated_count += 1 if trainee.update(activated: new_status)
    end
    updated_count
  end

  def flash_no_selection
    flash[:danger] = t(".trainee_no_selection")
    redirect_to supervisor_users_path
  end

  def set_css_class
    @page_class = Settings.page_classes.trainee_manager
  end

  def check_permissions
    return unless current_user.trainee?

    flash[:danger] = t(".unauthorized_access")
    redirect_to root_path
  end
end
