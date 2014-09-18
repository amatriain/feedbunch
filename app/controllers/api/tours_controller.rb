##
# Controller to retrieve i18n strings for application tours.

class Api::ToursController < ApplicationController

  before_filter :authenticate_user!

  respond_to :json

  ##
  # Return JSON object with i18n strings for the main application tour.

  def show_main
    render 'show_main'
  rescue => e
    handle_error e
  end
end