##
# Controller to retrieve configuration for the current user

class Api::UserConfigsController < ApplicationController

  before_filter :authenticate_user!

  respond_to :json

  ##
  # Return configuration options set by the user

  def show
    # If config has not changed, return a 304
    if stale? etag: EtagCalculator.etag(current_user.config_updated_at),
              last_modified: current_user.config_updated_at
      @user = current_user
      respond_with current_user
    end
  rescue => e
    handle_error e
  end

  ##
  # Change configuration settings for the current user.

  def update
    show_main_tour = param_str_to_boolean :show_main_tour, config_params
    show_mobile_tour = param_str_to_boolean :show_mobile_tour, config_params
    show_feed_tour = param_str_to_boolean :show_feed_tour, config_params
    show_entry_tour = param_str_to_boolean :show_entry_tour, config_params

    current_user.update_config show_main_tour: show_main_tour,
                               show_mobile_tour: show_mobile_tour,
                               show_feed_tour: show_feed_tour,
                               show_entry_tour: show_entry_tour
    head :ok
  rescue => e
    handle_error e
  end

  private

  def config_params
    params.require(:user_config).permit(:show_main_tour, :show_mobile_tour, :show_feed_tour, :show_entry_tour)
  end

end