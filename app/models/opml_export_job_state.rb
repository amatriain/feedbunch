##
# OpmlExportJobState model. Each instance of this class represents an ocurrence of a user exporting subscription data
# in OPML format.
#
# Each OpmlExportJobState belongs to a single user, and each user can have at most only one OpmlExportJobState (one-to-one relationship).
# If a user exports data several times, each time the previous OpmlExportJobState is updated.
#
# The OpmlExportJobState model has the following fields:
# - state: mandatory text that indicates the current state of the export process. Supported values are
# "NONE" (the default), "RUNNING", "SUCCESS" and "ERROR".
# - show_alert: if true (the default), show an alert in the Start page informing of the data export state. If false,
# the user has closed the alert related to OPML exports and doesn't want it to be displayed again.
# - filename: name of the OPML file exported. It only takes value if the state is "SUCCESS"

class OpmlExportJobState < ActiveRecord::Base
  # Class constants for the possible states
  NONE = 'NONE'
  RUNNING = 'RUNNING'
  ERROR = 'ERROR'
  SUCCESS = 'SUCCESS'

  belongs_to :user
  validates :user_id, presence: true

  validates :state, presence: true, inclusion: {in: [NONE, RUNNING, ERROR, SUCCESS]}
  validates :show_alert, inclusion: {in: [true, false]}
  validate :filename_present_only_if_job_successful

  before_validation :default_values

  private

  ##
  # By default, a OpmlExportJobState is in the "NONE" state unless specified otherwise.

  def default_values
    self.state = NONE if self.state.blank?
    self.show_alert = true if self.show_alert.nil?
  end

  ##
  # Validate that the filename attribute is present if and only if the job state is "SUCCESS"

  def filename_present_only_if_job_successful
    if state == SUCCESS && filename.blank?
      errors.add :filename, "can't be blank if the job state is SUCCESS"
    elsif state != SUCCESS && filename.present?
      errors.add :filename, "must be blank if the job state is different from SUCCESS"
    end
  end
end
