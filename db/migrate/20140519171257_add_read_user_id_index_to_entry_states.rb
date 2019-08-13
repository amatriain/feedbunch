class AddReadUserIdIndexToEntryStates < ActiveRecord::Migration[5.2]
  def change
    add_index :entry_states, [:read, :user_id], name: 'index_entry_states_on_read_user_id'
  end
end
