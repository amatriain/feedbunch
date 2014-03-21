##
# Controller to import and export subscriptions data

class DataImportsController < ApplicationController

  before_filter :authenticate_user!

  respond_to :html, only: [:create]
  respond_to :json, only: [:show]

  ##
  # Return JSON indicating the status of the "import subscriptions" process for the current user

  def show
    if DataImport.exists? user_id: current_user.id
      data_import = DataImport.where(user_id: current_user.id).first
    else
      Rails.logger.warn "User #{current_user.id} - #{current_user.email} has no DataImport, creating one with status NONE"
      data_import = current_user.create_data_import status: DataImport::NONE
    end

    Rails.logger.debug "DataImport for user #{current_user.id} - #{current_user.email}: id #{data_import.try :id}, status #{data_import.try :status}"
    render 'show', locals: {data_import: data_import}
  end

  ##
  # Upload a subscriptions data file (probably exported from Google Reader) and subscribe the current user
  # to the feeds there.

  def create
    file = data_import_params[:file]
    current_user.import_subscriptions file.tempfile
  rescue => e
    Rails.logger.error "Error importing OPML for user #{current_user.id} - #{current_user.email}"
    data_import = current_user.create_data_import status: DataImport::ERROR
  ensure
    redirect_to read_path
  end

  private

  def data_import_params
    params.require(:data_import).permit(:file)
  end

end