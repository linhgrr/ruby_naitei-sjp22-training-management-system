class Admin::BaseController < ApplicationController
  before_action :authorize_admin
  before_action :set_count_create_task
  check_authorization

  private

  def authorize_admin
    authorize! :access, :admin
  end

  def set_count_create_task
    session[:count_create_task] ||= 0
  end
end
