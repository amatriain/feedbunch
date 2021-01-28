class RenameRefreshFeedJobStatusToRefreshFeedJobState < ActiveRecord::Migration[5.2]
  def change
    rename_table :refresh_feed_job_statuses, :refresh_feed_job_states
  end
end
