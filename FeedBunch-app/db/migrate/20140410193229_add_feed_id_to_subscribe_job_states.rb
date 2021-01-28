class AddFeedIdToSubscribeJobStates < ActiveRecord::Migration[5.2]
  def change
    add_column :subscribe_job_states, :feed_id, :integer
  end
end
