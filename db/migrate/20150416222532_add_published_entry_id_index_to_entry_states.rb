class AddPublishedEntryIdIndexToEntryStates < ActiveRecord::Migration
  def change
    add_index :entry_states, [:published, :entry_id], name: 'index_entry_states_on_order_fields'
  end
end
