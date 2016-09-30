require 'etag_calculator'

##
# Controller to retrieve data for the current user

class Api::UserDataController < ApplicationController

  before_action :authenticate_user!

  respond_to :json

  ##
  # Return data about the user

  def show
    # If data has not changed, return a 304
    if stale? etag: EtagCalculator.etag(current_user.user_data_updated_at),
              last_modified: current_user.user_data_updated_at
      @user = current_user
      respond_with @user
    end
  rescue => e
    handle_error e
  end
end