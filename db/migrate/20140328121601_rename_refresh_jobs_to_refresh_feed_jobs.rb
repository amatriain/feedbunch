class RenameRefreshJobsToRefreshFeedJobs < ActiveRecord::Migration
  def change
    rename_table :refresh_jobs, :refresh_feed_jobs
  end
end
