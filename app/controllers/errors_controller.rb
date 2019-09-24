# frozen_string_literal: true

##
# Controller to render dynamic error pages

class ErrorsController < ApplicationController
  respond_to :html

  ##
  # Show an error page.

  def show
    respond_with do |format|
      format.html {render status_code.to_s, status: status_code}
    end
  end

  protected

  ##
  # Use the http error code passed, or use 500 by default.

  def status_code
    params[:code] || 500
  end

end