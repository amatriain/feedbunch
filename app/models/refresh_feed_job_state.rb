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

class RefreshFeedJobState < ActiveRecord::Base
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

  private

  ##
  # By default, a RefreshFeedJobState is in the "RUNNING" state unless specified otherwise.

  def default_values
    self.state = RUNNING if self.state.blank?
  end
end
