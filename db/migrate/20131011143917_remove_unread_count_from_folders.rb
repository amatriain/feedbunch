class RemoveUnreadCountFromFolders < ActiveRecord::Migration
  def change
    remove_column :folders, :unread_entries
  end
end
