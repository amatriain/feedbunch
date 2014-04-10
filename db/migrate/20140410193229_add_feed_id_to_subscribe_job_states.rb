class AddFeedIdToSubscribeJobStates < ActiveRecord::Migration
  def change
    add_column :subscribe_job_states, :feed_id, :integer
  end
end
