class RenameStatusToState < ActiveRecord::Migration
  def change
    rename_column :refresh_feed_job_states, :status, :state
  end
end
