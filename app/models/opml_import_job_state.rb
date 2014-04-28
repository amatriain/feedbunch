##
# OpmlImportJobState model. Each instance of this class represents an ocurrence of a user importing subscription data
# (e.g. from Google Reader).
#
# Each OpmlImportJobState belongs to a single user, and each user can have at most only one OpmlImportJobState (one-to-one relationship).
# If a user imports data several times, each time the previous OpmlImportJobState is updated.
#
# The OpmlImportJobState model has the following fields:
# - state: mandatory text that indicates the current state of the import process. Supported values are
# "NONE" (the default), "RUNNING", "SUCCESS" and "ERROR".
# - total_feeds: number of feeds in the data file
# - processed_feeds: number of feeds in the data file already processed (the user is subscribed to the feed and
# entries have been fetched from it).
# - show_alert: if true (the default), show an alert in the Start page informing of the data import state. If false,
# the user has closed the alert related to OPML imports and doesn't want it to be displayed again.

class OpmlImportJobState < ActiveRecord::Base
  # Class constants for the possible states
  NONE = 'NONE'
  RUNNING = 'RUNNING'
  ERROR = 'ERROR'
  SUCCESS = 'SUCCESS'

  belongs_to :user
  validates :user_id, presence: true

  validates :state, presence: true, inclusion: {in: [NONE, RUNNING, ERROR, SUCCESS]}
  validates :total_feeds, presence: true
  validates :processed_feeds, presence: true
  validates :show_alert, inclusion: {in: [true, false]}

  before_validation :default_values

  private

  ##
  # By default, a OpmlImportJobState is in the "NONE" state unless specified otherwise.

  def default_values
    self.state = NONE if self.state.blank?
    self.total_feeds = 0 if self.total_feeds.blank?
    self.processed_feeds = 0 if self.processed_feeds.blank?
    self.show_alert = true if self.show_alert.nil?
  end
end
