class AddUniqueHashToDeletedEntries < ActiveRecord::Migration[5.2]
  def up
    add_column :deleted_entries, :unique_hash, :text, null: true
    remove_index :deleted_entries, name: "index_deleted_entries_on_guid_feed_id"
    add_index :deleted_entries, [:feed_id, :guid, :unique_hash], name: 'index_feedid_guid_hash_on_deleted_entries'
  end

  def down
    remove_index :deleted_entries, name: 'index_feedid_guid_hash_on_deleted_entries'
    add_index :deleted_entries, [:feed_id, :guid], name: "index_deleted_entries_on_guid_feed_id"
    remove_column :deleted_entries, :unique_hash
  end
end
