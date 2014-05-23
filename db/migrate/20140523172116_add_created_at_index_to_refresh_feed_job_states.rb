class AddCreatedAtIndexToRefreshFeedJobStates < ActiveRecord::Migration
  def change
    add_index :refresh_feed_job_states, [:created_at], name: 'index_refresh_feed_job_states_on_created_at'
  end
end
