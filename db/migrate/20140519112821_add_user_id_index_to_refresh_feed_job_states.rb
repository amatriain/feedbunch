class AddUserIdIndexToRefreshFeedJobStates < ActiveRecord::Migration[5.2]
  def change
    add_index :refresh_feed_job_states, [:user_id], name: 'index_refresh_feed_job_states_on_user_id'
  end
end
