##
# Controller to retrieve data for the current user

class Api::UserDataController < ApplicationController

  before_filter :authenticate_user!

  respond_to :json

  ##
  # Return data about the user

  def show
    render 'show', locals: {user: current_user}
  rescue => e
    handle_error e
  end
end