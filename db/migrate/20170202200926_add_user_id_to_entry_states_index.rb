class AddUserIdToEntryStatesIndex < ActiveRecord::Migration[5.0]
  def change
    remove_index :entry_states, name: 'index_entry_states_on_order_fields'
    add_index :entry_states, [:published, :entry_created_at, :entry_id, :user_id],
              order: {published: :desc, entry_created_at: :desc, entry_id: :desc},
              name: 'index_entry_states_on_order_fields'
  end
end
