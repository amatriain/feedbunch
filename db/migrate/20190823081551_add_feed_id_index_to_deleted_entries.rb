class AddFeedIdIndexToDeletedEntries < ActiveRecord::Migration[5.2]
  def change
    add_index :deleted_entries, [:feed_id], name: 'index_feed_id_on_deleted_entries'
  end
end
