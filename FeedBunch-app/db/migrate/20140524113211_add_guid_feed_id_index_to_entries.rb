class AddGuidFeedIdIndexToEntries < ActiveRecord::Migration[5.2]
  def change
    add_index :entries, [:guid, :feed_id], name: 'index_entries_on_guid_feed_id'
  end
end
