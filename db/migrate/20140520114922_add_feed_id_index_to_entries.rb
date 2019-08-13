class AddFeedIdIndexToEntries < ActiveRecord::Migration[5.2]
  def change
    add_index :entries, [:feed_id], name: 'index_entries_on_feed_id'
  end
end
