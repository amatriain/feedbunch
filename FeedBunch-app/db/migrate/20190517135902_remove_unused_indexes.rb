class RemoveUnusedIndexes < ActiveRecord::Migration[5.2]
  def change
    remove_index :entry_states, name: "index_entry_states_on_order_fields"
    remove_index :entry_states, name: "index_entry_states_unread_on_order_fields"
  end
end
