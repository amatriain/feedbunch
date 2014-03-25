##
# Controller to retrieve data for the current user

class Api::UserDataController < ApplicationController

  before_filter :authenticate_user!

  respond_to :json

  ##
  # Return configuration options set by the user

  def show
    render 'show', locals: {user: current_user}
  end
end