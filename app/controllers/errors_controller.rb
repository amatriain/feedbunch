##
# Controller to render dynamic error pages

class ErrorsController < ApplicationController

  ##
  # Show an error page.

  def show
    render status_code.to_s, status: status_code
  end

  protected

  ##
  # Use the http error code passed, or use 500 by default.

  def status_code
    params[:code] || 500
  end

end