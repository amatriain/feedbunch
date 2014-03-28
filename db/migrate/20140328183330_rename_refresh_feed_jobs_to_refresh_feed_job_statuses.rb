class RenameRefreshFeedJobsToRefreshFeedJobStatuses < ActiveRecord::Migration
  def change
    rename_table :refresh_feed_jobs, :refresh_feed_job_statuses
  end
end
