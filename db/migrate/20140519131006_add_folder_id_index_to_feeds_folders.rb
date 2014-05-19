class AddFolderIdIndexToFeedsFolders < ActiveRecord::Migration
  def change
    add_index :feeds_folders, [:folder_id], name: 'index_feeds_folders_on_folder_id'
  end
end
