##
# Controller to access the main application page

class ReadController < ApplicationController

  before_action :authenticate_user!

  respond_to :html

  ##
  # return the main application page

  def index
    respond_with
  rescue => e
    handle_error e
  end

end
