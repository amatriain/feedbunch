##
# Controller to query the status of RefreshFeedJob instances enqued for the user.

class Api::RefreshFeedJobStatusesController < ApplicationController

  before_filter :authenticate_user!

  respond_to :json, only: [:index, :show]

  ##
  # Return JSON indicating the status of the "refresh feed" processes initiated by the current user

  def index
    if RefreshFeedJobStatus.exists? user_id: current_user.id
      @job_statuses = RefreshFeedJobStatus.where user_id: current_user.id
    else
      head status: 404
    end

    Rails.logger.debug "User #{current_user.id} - #{current_user.email} has #{@job_statuses.count} RefreshFeedJobStatus instances"
    render 'index', locals: {job_statuses: @job_statuses}
  rescue => e
    handle_error e
  end

  ##
  # Return JSON indicating the status of a single "refresh feed" process initiated by the current user

  def show
    @job_status = current_user.refresh_feed_job_statuses.find params[:id]
    render 'show', locals: {job_status: @job_status}
  rescue => e
    handle_error e
  end

end