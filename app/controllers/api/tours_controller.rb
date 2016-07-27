##
# Controller to retrieve i18n strings for application tours.

class Api::ToursController < ApplicationController

  before_action :authenticate_user!

  respond_to :json

  ##
  # Return JSON object with i18n strings for the main application tour.

  def show_main
    respond_with
  rescue => e
    handle_error e
  end

  ##
  # Return JSON object with i18n strings for the mobile application tour.

  def show_mobile
    respond_with
  rescue => e
    handle_error e
  end

  ##
  # Return JSON object with i18n strings for the feed application tour.

  def show_feed
    respond_with
  rescue => e
    handle_error e
  end

  ##
  # Return JSON object with i18n strings for the entry application tour.

  def show_entry
    respond_with
  rescue => e
    handle_error e
  end

  ##
  # Return JSON object with i18n strings for the keyboard shortcuts application tour.

  def show_kb_shortcuts
    respond_with
  rescue => e
    handle_error e
  end
end