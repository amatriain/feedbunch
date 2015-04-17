class AddEntryCreatedAtToEntryStatesIndex < ActiveRecord::Migration
  def up
    add_index :entry_states, [:published, :entry_created_at, :entry_id], name: 'index_entry_states_on_order_fields'
  end

  def down
    remove_index :entry_states, name: 'index_entry_states_on_order_fields'
  end
end
