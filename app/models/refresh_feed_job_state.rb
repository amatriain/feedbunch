# frozen_string_literal: true

##
# RefreshFeedJobState model. Each instance of this class represents an ocurrence of a user manually requesting
# a refresh of a feed
#
# Each RefreshFeedJobState belongs to a single user, and each user can have many RefreshFeedJobStates (one-to-many relationship).
# Each RefreshFeedJobState belongs to a single feed, and each feed can have many RefreshFeedJobStates (one-to-many relationship).
#
# The RefreshFeedJobState model has the following fields:
# - state: mandatory text that indicates the current state of the import process. Supported values are
# "RUNNING" (the default), "SUCCESS" and "ERROR".

class RefreshFeedJobState < ApplicationRecord
  # Class constants for the possible states
  RUNNING = 'RUNNING'
  ERROR = 'ERROR'
  SUCCESS = 'SUCCESS'

  belongs_to :user
  validates :user_id, presence: true

  belongs_to :feed
  validates :feed_id, presence: true

  validates :state, presence: true, inclusion: {in: [RUNNING, ERROR, SUCCESS]}

  before_validation :default_values
  after_save :touch_refresh_feed_job_states
  after_destroy :touch_refresh_feed_job_states

  private

  ##
  # Update the refresh_feed_jobs_updated_at attribute of the associated user with the current datetime.

  def touch_refresh_feed_job_states
    user.update refresh_feed_jobs_updated_at: Time.zone.now if user.present?
  end

  ##
  # By default, a RefreshFeedJobState is in the "RUNNING" state unless specified otherwise.

  def default_values
    self.state = RUNNING if self.state.blank?
  end
end
