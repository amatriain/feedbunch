require 'etag_calculator'

##
# Controller to import subscriptions data

class Api::OpmlImportsController < ApplicationController

  before_action :authenticate_user!

  respond_to :html, only: [:create]
  respond_to :json, only: [:show, :update]

  ##
  # Return JSON indicating the state of the "import subscriptions" process for the current user

  def show
    if OpmlImportJobState.exists? user_id: current_user.id
      @opml_import_job_state = OpmlImportJobState.find_by user_id: current_user.id
    else
      Rails.logger.warn "User #{current_user.id} - #{current_user.email} has no OpmlImportJobState, creating one with state NONE"
      @opml_import_job_state = current_user.create_opml_import_job_state state: OpmlImportJobState::NONE
    end

    # If opml export state has not changed, return a 304
    if stale? etag: EtagCalculator.etag(@opml_import_job_state.updated_at),
              last_modified: @opml_import_job_state.updated_at
      Rails.logger.debug "OpmlImportJobState for user #{current_user.id} - #{current_user.email}: id #{@opml_import_job_state&.id}, state #{@opml_import_job_state&.state}"
      respond_with @opml_import_job_state
    end
  rescue => e
    handle_error e
  end

  ##
  # Upload a subscriptions data file (probably exported from another feed reader) and subscribe the current user
  # to the feeds there.

  def create
    file = opml_import_params[:file]
    current_user.import_subscriptions file.tempfile
  rescue => e
    Rails.logger.error "Error importing OPML for user #{current_user.id} - #{current_user.email}"
    Rails.logger.error e.message
    Rails.logger.error e.backtrace
    opml_import_job_state = current_user.create_opml_import_job_state state: OpmlImportJobState::ERROR
  ensure
    redirect_to read_path
  end

  ##
  # Update the OpmlImportJobState for the current user. Currently the only supported change is showing or hiding the alert
  # displaying the state of the process.

  def update
    @opml_import_job_state = current_user.opml_import_job_state
    # Only if the string "false" is sent, set visibility to false. If anything else
    # is sent in the :show_alert request parameter, set visibility to true. This is the
    # safest default.
    if opml_import_params[:show_alert]=='false'
      show_alert = false
    else
      show_alert = true
    end
    current_user.set_opml_import_job_state_visible show_alert
    head :ok
  rescue => e
    handle_error e
  end

  private

  def opml_import_params
    params.require(:opml_import).permit(:file, :show_alert)
  end

end