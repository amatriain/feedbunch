require 'etag_calculator'

##
# Controller to retrieve configuration for the current user

class Api::UserConfigsController < ApplicationController

  before_action :authenticate_user!

  respond_to :json

  ##
  # Return configuration options set by the user

  def show
    # If config has not changed, return a 304
    if stale? etag: EtagCalculator.etag(current_user.config_updated_at),
              last_modified: current_user.config_updated_at
      @user = current_user

      # Keyboard shortcuts for all users are set in application configuration
      @kb_shortcuts = {}
      @kb_shortcuts[:select_sidebar_link] = Feedbunch::Application.config.kb_select_sidebar_link
      @kb_shortcuts[:toggle_open_entry] = Feedbunch::Application.config.kb_toggle_open_entry
      @kb_shortcuts[:sidebar_link_up] = Feedbunch::Application.config.kb_sidebar_link_up
      @kb_shortcuts[:sidebar_link_down] = Feedbunch::Application.config.kb_sidebar_link_down
      @kb_shortcuts[:entries_up] = Feedbunch::Application.config.kb_entries_up
      @kb_shortcuts[:entries_down] = Feedbunch::Application.config.kb_entries_down
      @kb_shortcuts[:toggle_show_read] = Feedbunch::Application.config.kb_toggle_show_read
      @kb_shortcuts[:mark_all_read] = Feedbunch::Application.config.kb_mark_all_read
      @kb_shortcuts[:toggle_read_entry] = Feedbunch::Application.config.kb_toggle_read_entry

      respond_with @user, @kb_shortcuts
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
    show_kb_shortcuts_tour = param_str_to_boolean :show_kb_shortcuts_tour, config_params

    current_user.update_config show_main_tour: show_main_tour,
                               show_mobile_tour: show_mobile_tour,
                               show_feed_tour: show_feed_tour,
                               show_entry_tour: show_entry_tour,
                               show_kb_shortcuts_tour: show_kb_shortcuts_tour
    head :ok
  rescue => e
    handle_error e
  end

  private

  def config_params
    params.require(:user_config).permit(:show_main_tour, :show_mobile_tour, :show_feed_tour, :show_entry_tour,
                                        :show_kb_shortcuts_tour)
  end

end