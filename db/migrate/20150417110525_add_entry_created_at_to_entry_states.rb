class AddEntryCreatedAtToEntryStates < ActiveRecord::Migration
  def up
    add_column :entry_states, :entry_created_at, :datetime, null: true
  end

  def down
    remove_column :entry_states, :entry_created_at
  end
end
