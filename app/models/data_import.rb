##
# DataImport model. Each instance of this class represents an ocurrence of a user importing subscription data
# (e.g. from Google Reader).
#
# Each DataImport belongs to a single user, and each user can have at most only one DataImport (one-to-one relationship).
# If a user imports data several times, each time the previous DataImport is updated.
#
# The DataImport model has the following fields:
# - status: mandatory text that indicates the current status of the import process. Supported values are
# "RUNNING", "SUCCESS" and "ERROR".
# - total_feeds: number of feeds in the data file
# - processed_feeds: number of feeds in the data file already processed (the user is subscribed to the feed and
# entries have been fetched from it).

class DataImport < ActiveRecord::Base
  attr_accessible # none

  belongs_to :user
  validates :user_id, presence: true

  validates :status, presence: true, inclusion: {in: %w{RUNNING ERROR SUCCESS}}
end
