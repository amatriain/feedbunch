class RemoveUnreadCountFromFolders < ActiveRecord::Migration[5.2]
  def change
    remove_column :folders, :unread_entries
  end
end
