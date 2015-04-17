class AddDenormalizedColsToEntryStates < ActiveRecord::Migration
  def up
    add_column :entry_states, :published, :datetime, null: true
    add_column :entry_states, :entry_created_at, :datetime, null: true

    EntryState.all.find_each do |es|
      es.update published: es.entry.published,
                entry_created_at: es.entry.created_at
    end

    # Set not null constraint after giving a published value to all columns, otherwise the database will respond with an error
    change_column_null :entry_states, :published, false, Time.zone.now
    change_column_null :entry_states, :entry_created_at, false, Time.zone.now
  end

  def down
    remove_column :entry_states, :published
    remove_column :entry_states, :entry_created_at
  end
end
