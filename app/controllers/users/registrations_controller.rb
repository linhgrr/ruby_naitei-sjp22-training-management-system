# frozen_string_literal: true

class Users::RegistrationsController < Devise::RegistrationsController
  before_action :configure_sign_up_params, only: [:create]
  before_action :configure_account_update_params, only: [:update]

  # POST /resource
  # rubocop:disable Lint/UselessMethodDefinition
  def create
    super
  end

  # PUT /resource
  def update
    super
  end
  # rubocop:enable Lint/UselessMethodDefinition

  protected

  def configure_sign_up_params
    devise_parameter_sanitizer.permit(:sign_up,
                                      keys: [:name, :birthday, :gender])
  end

  def configure_account_update_params
    devise_parameter_sanitizer.permit(:account_update,
                                      keys: [:name, :birthday, :gender])
  end
end
