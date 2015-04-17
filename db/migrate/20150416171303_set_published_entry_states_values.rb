class SetPublishedEntryStatesValues < ActiveRecord::Migration
  def up
    EntryState.all.find_each do |es|
      es.update published: es.entry.published
    end

    # Set not null constraint after giving a published value to all columns, otherwise the database will respond with an error
    change_column_null :entry_states, :published, false, Time.zone.now
  end

  def down
    remove_column :entry_states, :published
  end
end
