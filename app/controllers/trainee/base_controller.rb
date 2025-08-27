class Trainee::BaseController < ApplicationController
  before_action :authorize_trainee
  check_authorization

  private

  def authorize_trainee
    authorize! :access, :trainee
  end
end
