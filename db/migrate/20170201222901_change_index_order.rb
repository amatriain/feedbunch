class ChangeIndexOrder < ActiveRecord::Migration[5.0]
  def up
    remove_index :entries, name: 'index_entries_on_published_created_at_id'
    add_index :entries, [:published, :created_at, :id],
              order: {published: :desc, created_at: :desc, id: :desc},
              name: 'index_entries_on_published_created_at_id'

    remove_index :entry_states, name: 'index_entry_states_on_order_fields'
    add_index :entry_states, [:published, :entry_created_at, :entry_id],
              order: {published: :desc, entry_created_at: :desc, entry_id: :desc},
              name: 'index_entry_states_on_order_fields'
  end

  def down
    remove_index :entries, name: 'index_entries_on_published_created_at_id'
    add_index :entries, [:published, :created_at, :id], name: 'index_entries_on_published_created_at_id'

    remove_index :entry_states, name: 'index_entry_states_on_order_fields'
    add_index :entry_states, [:published, :entry_created_at, :entry_id], name: 'index_entry_states_on_order_fields'
  end
end
