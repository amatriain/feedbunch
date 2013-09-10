##
# Controller to import and export subscriptions data

class DataImportsController < ApplicationController

  before_filter :authenticate_user!

  respond_to :html, only: [:create]
  respond_to :json, only: [:show]

  ##
  # Return JSON indicating the status of the "import subscriptions" process for the current user

  def show
    render 'show', locals: {user: current_user}
  end

  ##
  # Upload a subscriptions data file (probably exported from Google Reader) and subscribe the current user
  # to the feeds there.

  def create
    file = data_import_params[:file]
    current_user.import_subscriptions file.tempfile
    redirect_to read_path
  rescue => e
    handle_error e
  end

  private

  def data_import_params
    params.require(:data_import).permit(:file)
  end

end