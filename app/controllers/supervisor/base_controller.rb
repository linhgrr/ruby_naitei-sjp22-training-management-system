class Supervisor::BaseController < ApplicationController
  before_action :authorize_supervisor
  check_authorization

  private

  def authorize_supervisor
    authorize! :access, :supervisor
  end
end
