##
# Controller to query the status of RefreshFeedJob instances enqued for the user.

class Api::RefreshFeedJobStatesController < ApplicationController

  before_filter :authenticate_user!

  respond_to :json

  ##
  # Return JSON indicating the status of the "refresh feed" processes initiated by the current user

  def index
    if RefreshFeedJobState.exists? user_id: current_user.id
      @job_statuses = RefreshFeedJobState.where user_id: current_user.id
      Rails.logger.debug "User #{current_user.id} - #{current_user.email} has #{@job_statuses.count} RefreshFeedJobState instances"
      render 'index', locals: {job_statuses: @job_statuses}
    else
      head status: 404
    end
  rescue => e
    handle_error e
  end

  ##
  # Return JSON indicating the status of a single "refresh feed" process initiated by the current user

  def show
    @job_status = current_user.find_refresh_feed_job_status params[:id]
    render 'show', locals: {job_status: @job_status}
  rescue => e
    handle_error e
  end

  ##
  # Remove job status from the database. This will make its alert disappear from the start page as well.

  def destroy
    @job_status = current_user.refresh_feed_job_statuses.find params[:id]
    Rails.logger.debug "Destroying refresh_feed_job_status #{@job_status.id} for user #{current_user.id} - #{current_user.email}"
    @job_status.destroy!
    head status: 200
  rescue => e
    handle_error e
  end

end