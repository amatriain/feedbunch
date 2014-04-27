##
# Controller to import and export subscriptions data

class Api::DataExportsController < ApplicationController

  before_filter :authenticate_user!

  respond_to :html, only: [:create]

  ##
  # Return JSON indicating the state of the "import subscriptions" process for the current user

  # def show
  #   if DataImport.exists? user_id: current_user.id
  #     data_import = DataImport.where(user_id: current_user.id).first
  #   else
  #     Rails.logger.warn "User #{current_user.id} - #{current_user.email} has no DataImport, creating one with state NONE"
  #     data_import = current_user.create_data_import state: DataImport::NONE
  #   end
  #
  #   Rails.logger.debug "DataImport for user #{current_user.id} - #{current_user.email}: id #{data_import.try :id}, state #{data_import.try :state}"
  #   render 'show', locals: {data_import: data_import}
  # rescue => e
  #   handle_error e
  # end

  ##
  # Export a user's subscriptions in OPML format.

  def create
    current_user.export_subscriptions
  rescue => e
    Rails.logger.error "Error exporting OPML data for user #{user.email} - #{user.name}"
    Rails.logger.error error.message
    Rails.logger.error error.backtrace
    #data_import = current_user.create_data_import state: DataImport::ERROR
  ensure
    redirect_to read_path
  end

  ##
  # Update the DataImport for the current user. Currently the only supported change is showing or hiding the alert
  # displaying the state of the process.

  # def update
  #   @data_import = current_user.data_import
  #   # Only if the string "false" is sent, set visibility to false. If anything else
  #   # is sent in the :show_alert request parameter, set visibility to true. This is the
  #   # safest default.
  #   if data_import_params[:show_alert]=='false'
  #     show_alert = false
  #   else
  #     show_alert = true
  #   end
  #   current_user.set_data_import_visible show_alert
  #   head :ok
  # rescue => e
  #   handle_error e
  # end

  private

  # def data_import_params
  #   params.require(:data_import).permit(:file, :show_alert)
  # end

end