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
end