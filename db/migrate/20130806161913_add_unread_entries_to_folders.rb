class AddUnreadEntriesToFolders < ActiveRecord::Migration
  def change
    add_column :folders, :unread_entries, :integer

    Folder.all.each do |f|
      user = f.user
      unread_entries = user.unread_folder_entries(f.id).count
      f.update_column :unread_entries, unread_entries
    end
  end
end
