class AddUserIdIndexToSubscribeJobStates < ActiveRecord::Migration
  def change
    add_index :subscribe_job_states, [:user_id], name: 'index_subscribe_job_states_on_user_id'
  end
end
