class RenameStatusToState < ActiveRecord::Migration[5.2]
  def change
    rename_column :refresh_feed_job_states, :status, :state
  end
end
