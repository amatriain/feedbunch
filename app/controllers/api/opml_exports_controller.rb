require 'etag_calculator'
require 'opml_exporter'

##
# Controller to export subscriptions data

class Api::OpmlExportsController < ApplicationController

  before_action :authenticate_user!

  respond_to :html, only: [:create]
  respond_to :json, only: [:show, :update, :download]

  ##
  # Return JSON indicating the state of the "export subscriptions" process for the current user

  def show
    if OpmlExportJobState.exists? user_id: current_user.id
      @opml_export_job_state = OpmlExportJobState.find_by user_id: current_user.id
    else
      Rails.logger.warn "User #{current_user.id} - #{current_user.email} has no OpmlExportJobState, creating one with state NONE"
      @opml_export_job_state = current_user.create_opml_export_job_state state: OpmlExportJobState::NONE
    end

    # If opml export state has not changed, return a 304
    if stale? etag: EtagCalculator.etag(@opml_export_job_state.updated_at),
              last_modified: @opml_export_job_state.updated_at
      Rails.logger.debug "OpmlExportJobState for user #{current_user.id} - #{current_user.email}: id #{@opml_export_job_state&.id}, state #{@opml_export_job_state&.state}"
      respond_with @opml_export_job_state
    end
  rescue => e
    handle_error e
  end

  ##
  # Export a user's subscriptions in OPML format.

  def create
    current_user.export_subscriptions
  rescue => e
    Rails.logger.error "Error exporting OPML data for user #{current_user.email} - #{current_user.name}"
    Rails.logger.error e.message
    Rails.logger.error e.backtrace
    current_user.create_opml_export_job_state state: OpmlExportJobState::ERROR
  ensure
    redirect_to read_path
  end

  ##
  # Update the OpmlExportJobState for the current user. Currently the only supported change is showing or hiding the alert
  # displaying the state of the process.

  def update
    @opml_export_job_state = current_user.opml_export_job_state
    # Only if the string "false" is sent, set visibility to false. If anything else
    # is sent in the :show_alert request parameter, set visibility to true. This is the
    # safest default.
    if opml_export_job_state_params[:show_alert]=='false'
      show_alert = false
    else
      show_alert = true
    end
    current_user.set_opml_export_job_state_visible show_alert
    head :ok
  rescue => e
    handle_error e
  end

  ##
  # Download the OPML file previously exported by a user.

  def download
    @data = current_user.get_opml_export
    send_data @data, filename: OPMLExporter::FILENAME, type: 'application/xml', disposition: 'attachment', status: '200'
  rescue => e
    Rails.logger.error "Error downloading OPML export file for user #{current_user.email} - #{current_user.name}"
    Rails.logger.error e.message
    Rails.logger.error e.backtrace
    flash[:alert] = t 'read.alerts.opml_export.download_error'
    redirect_to read_path
  end

  private

  def opml_export_job_state_params
    params.require(:opml_export).permit(:show_alert)
  end

end