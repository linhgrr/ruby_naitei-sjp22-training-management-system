class StaticPagesController < ApplicationController
  skip_before_action :authenticate_user!, only: :home
  skip_authorization_check

  # GET / (root)
  # GET /static_pages/home
  def home
    return redirect_manager if manager?

    return unless user_signed_in?

    load_trainee_courses
  end

  def manager?
    current_user&.admin? || current_user&.supervisor?
  end

  def redirect_manager
    redirect_to admin_dashboards_path if current_user&.admin?
    redirect_to supervisor_courses_path if current_user&.supervisor?
  end

  def load_trainee_courses
    @pagy, @courses = pagy(
      current_user.courses
                  .by_status(params[:status])
                  .ordered_by_start_date
                  .includes(:user)
                  .with_attached_image,
      items: Settings.ui.items_per_page
    )
  end

  private
  def trainee_dashboard
    @pagy, @courses = pagy(
      current_user.courses
                  .by_status(params[:status])
                  .ordered_by_start_date
                  .includes(:user)
                  .with_attached_image,
      items: Settings.ui.items_per_page
    )
  end
end
