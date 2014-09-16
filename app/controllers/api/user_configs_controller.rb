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
    show_main_tour_str = config_params[:show_main_tour]
    if show_main_tour_str=='true'
      show_main_tour = true
    elsif show_main_tour_str=='false'
      show_main_tour = false
    else
      Rails.logger.warn "Unexpected value received for show_main_tour: #{show_main_tour_str}"
      raise ActionController::ParameterMissing.new 'show_main_tour'
    end

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
    params.require(:user_config).permit(:show_main_tour)
  end
end