class AddUserIdIndexToEntryStates < ActiveRecord::Migration
  def change
    add_index :entry_states, [:user_id], name: 'index_entry_states_on_user_id'
  end
end
