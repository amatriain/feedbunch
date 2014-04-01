##
# Controller to query the status of RefreshFeedJob instances enqued for the user.

class Api::RefreshFeedJobStatusesController < ApplicationController

  before_filter :authenticate_user!

  respond_to :json, only: [:show]

  ##
  # Return JSON indicating the status of the "refresh feed" processes initiated by the current user

  def show
    if RefreshFeedJobStatus.exists? user_id: current_user.id
      job_statuses = RefreshFeedJobStatus.where user_id: current_user.id
    else
      head status: 404
    end

    Rails.logger.debug "User #{current_user.id} - #{current_user.email} has #{job_statuses.count} RefreshFeedJobStatus instances"
    render 'show', locals: {job_statuses: job_statuses, user: current_user}
  end

end