class AddEntryCreatedAtToEntryStates < ActiveRecord::Migration
  def up
    add_column :entry_states, :entry_created_at, :datetime, null: true

    EntryState.all.each do |es|
      es.update entry_created_at: es.entry.created_at
    end

    # Set not null constraint after giving a published value to all columns, otherwise the database will respond with an error
    change_column_null :entry_states, :entry_created_at, false, Time.zone.now
  end

  def down
    remove_column :entry_states, :entry_created_at
  end
end
