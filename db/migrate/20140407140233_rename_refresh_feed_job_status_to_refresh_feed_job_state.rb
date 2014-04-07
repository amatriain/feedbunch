class RenameRefreshFeedJobStatusToRefreshFeedJobState < ActiveRecord::Migration
  def change
    rename_table :refresh_feed_job_statuses, :refresh_feed_job_states
  end
end
