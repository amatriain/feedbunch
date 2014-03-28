##
# RefreshFeedJobStatus model. Each instance of this class represents an ocurrence of a user manually requesting
# a refresh of a feed
#
# Each RefreshFeedJobStatus belongs to a single user, and each user can have many RefreshJobs (one-to-many relationship).
# Each RefreshFeedJobStatus belongs to a single feed, and each feed can have many RefreshJobs (one-to-many relationship).
#
# The RefreshFeedJobStatus model has the following fields:
# - status: mandatory text that indicates the current status of the import process. Supported values are
# "RUNNING" (the default), "SUCCESS" and "ERROR".

class RefreshFeedJobStatus < ActiveRecord::Base
  # Class constants for the possible statuses
  RUNNING = 'RUNNING'
  ERROR = 'ERROR'
  SUCCESS = 'SUCCESS'

  belongs_to :user
  validates :user_id, presence: true

  belongs_to :feed
  validates :feed_id, presence: true

  validates :status, presence: true, inclusion: {in: [RUNNING, ERROR, SUCCESS]}

  before_validation :default_values

  private

  ##
  # By default, a RefreshFeedJobStatus is in the "RUNNING" status unless specified otherwise.

  def default_values
    self.status = RUNNING if self.status.blank?
  end
end
