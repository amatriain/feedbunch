class AddPublishedToEntryStates < ActiveRecord::Migration
  def up
    add_column :entry_states, :published, :datetime, null: true
  end

  def down
    remove_column :entry_states, :published
  end
end
