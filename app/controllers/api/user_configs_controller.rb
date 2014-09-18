##
# Controller to retrieve configuration for the current user

class Api::UserConfigsController < ApplicationController

  before_filter :authenticate_user!

  respond_to :json

  ##
  # Return configuration options set by the user

  def show
    render 'show', locals: {user: current_user}
  rescue => e
    handle_error e
  end

  ##
  # Change configuration settings for the current user.

  def update
    show_main_tour = param_str_to_boolean :show_main_tour
    show_mobile_tour = param_str_to_boolean :show_mobile_tour

    if !show_main_tour.nil?
      Rails.logger.info "Updating config for user #{current_user.email} - #{current_user.name}. Setting show_main_tour to #{show_main_tour}"
      current_user.update show_main_tour: show_main_tour
    end

    head :ok
  rescue => e
    handle_error e
  end

  private

  def config_params
    params.require(:user_config).permit(:show_main_tour, :show_mobile_tour)
  end

  ##
  # Convert a string parameter to boolean. The value of the param must be "true" or "false", otherwise an error is raised.
  # Receives a symbol indicating the parameter to convert as argument

  def param_str_to_boolean(param)
    param_str = config_params[param]
    param = nil

    if param_str == 'true'
      param = true
    elsif param_str == 'false'
      param = false
    elsif !param_str.nil?
      Rails.logger.warn "Unexpected value received for #{param}: #{param_str}"
      raise ActionController::ParameterMissing.new 'show_main_tour'
    end

    return param
  end
end