##
# Controller to import and export subscriptions data

class Api::DataExportsController < ApplicationController

  before_filter :authenticate_user!

  respond_to :html, only: [:create]

  ##
  # Return JSON indicating the state of the "import subscriptions" process for the current user

  # def show
  #   if OpmlImportJobState.exists? user_id: current_user.id
  #     opml_import_job_state = OpmlImportJobState.where(user_id: current_user.id).first
  #   else
  #     Rails.logger.warn "User #{current_user.id} - #{current_user.email} has no OpmlImportJobState, creating one with state NONE"
  #     opml_import_job_state = current_user.create_opml_import_job_state state: OpmlImportJobState::NONE
  #   end
  #
  #   Rails.logger.debug "OpmlImportJobState for user #{current_user.id} - #{current_user.email}: id #{opml_import_job_state.try :id}, state #{opml_import_job_state.try :state}"
  #   render 'show', locals: {opml_import_job_state: opml_import_job_state}
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
    #opml_import_job_state = current_user.create_opml_import_job_state state: OpmlImportJobState::ERROR
  ensure
    redirect_to read_path
  end

  ##
  # Update the OpmlImportJobState for the current user. Currently the only supported change is showing or hiding the alert
  # displaying the state of the process.

  # def update
  #   @opml_import_job_state = current_user.opml_import_job_state
  #   # Only if the string "false" is sent, set visibility to false. If anything else
  #   # is sent in the :show_alert request parameter, set visibility to true. This is the
  #   # safest default.
  #   if opml_import_job_state_params[:show_alert]=='false'
  #     show_alert = false
  #   else
  #     show_alert = true
  #   end
  #   current_user.set_opml_import_job_state_visible show_alert
  #   head :ok
  # rescue => e
  #   handle_error e
  # end

  private

  # def opml_import_job_state_params
  #   params.require(:opml_import_job_state).permit(:file, :show_alert)
  # end

end