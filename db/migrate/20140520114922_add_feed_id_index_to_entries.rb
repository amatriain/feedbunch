class AddFeedIdIndexToEntries < ActiveRecord::Migration
  def change
    add_index :entries, [:feed_id], name: 'index_entries_on_feed_id'
  end
end
