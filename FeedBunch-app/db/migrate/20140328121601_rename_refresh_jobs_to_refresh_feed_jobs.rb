class RenameRefreshJobsToRefreshFeedJobs < ActiveRecord::Migration[5.2]
  def change
    rename_table :refresh_jobs, :refresh_feed_jobs
  end
end
