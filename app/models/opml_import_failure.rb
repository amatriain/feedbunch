##
# OPML Import Failure model. Each instance of this class represents a feed URL present in the OPML file uploaded
# by the user but which couldn't be imported (because the feed is unavailable, HTTP error returned, etc).
#
# Each opml_import_failure belongs to exactly one OpmlImportJobState instance.
#
# During an OPML import job, every time it is impossible to import a feed URL present in the OPML, an instance of
# this class is saved in the db. So, looking at OpmlImportFailures associated with a given OpmlImportJobState, it
# is possible to know which feeds have failed during the import, no matter if the import is finished or still running.
#
# Duplicate failure URLs are not allowed for a given OPML import.
#
# Attributes of the model:
# - opml_import_job_state_id: ID of the OpmlImportJobState to which belongs the failure.
# - url: url present in the OPML file that failed during import.

class OpmlImportFailure < ActiveRecord::Base
  belongs_to :opml_import_job_state
  validates :opml_import_job_state_id, presence: true
  validates :url, presence: true, uniqueness: {case_sensitive: false, scope: :opml_import_job_state_id}
end
