class AddEntryIdIndexToEntryStates < ActiveRecord::Migration
  def change
    add_index :entry_states, [:entry_id], name: 'index_entry_states_on_entry_id'
  end
end
