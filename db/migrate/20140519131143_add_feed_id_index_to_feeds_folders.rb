class AddFeedIdIndexToFeedsFolders < ActiveRecord::Migration[5.2]
  def change
    add_index :feeds_folders, [:feed_id], name: 'index_feeds_folders_on_feed_id'
  end
end
