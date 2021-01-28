class AddDenormalizedColsToEntryStates < ActiveRecord::Migration[5.2]
  def up
    add_column :entry_states, :published, :datetime, null: true
    add_column :entry_states, :entry_created_at, :datetime, null: true

    execute 'update entry_states set published=(select published from entries where entries.id=entry_states.entry_id)'
    execute 'update entry_states set entry_created_at=(select created_at from entries where entries.id=entry_states.entry_id)'

    # Set not null constraint after giving a published value to all columns, otherwise the database will respond with an error
    change_column_null :entry_states, :published, false, Time.zone.now
    change_column_null :entry_states, :entry_created_at, false, Time.zone.now
  end

  def down
    remove_column :entry_states, :published
    remove_column :entry_states, :entry_created_at
  end
end
