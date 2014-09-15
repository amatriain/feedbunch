##
# Controller to retrieve i18n strings for application tours.

class Api::TourI18nsController < ApplicationController

  before_filter :authenticate_user!

  respond_to :json

  ##
  # Return JSON object with i18n strings.

  def show
    render 'show'
  rescue => e
    handle_error e
  end
end