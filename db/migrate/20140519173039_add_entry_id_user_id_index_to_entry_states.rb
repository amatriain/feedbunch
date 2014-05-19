class AddEntryIdUserIdIndexToEntryStates < ActiveRecord::Migration
  def change
    add_index :entry_states, [:entry_id, :user_id], name: 'index_entry_states_on_entry_id_user_id'
  end
end
