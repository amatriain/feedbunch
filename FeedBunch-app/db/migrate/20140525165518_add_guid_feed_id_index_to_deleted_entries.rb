class AddGuidFeedIdIndexToDeletedEntries < ActiveRecord::Migration[5.2]
  def change
    add_index :deleted_entries, [:guid, :feed_id], name: 'index_deleted_entries_on_guid_feed_id'
  end
end
