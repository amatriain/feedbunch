class AddUnreadEntriesToUsers < ActiveRecord::Migration
  def change
    add_column :users, :unread_entries, :integer

    User.all.each do |u|
      unread_entries = u.unread_folder_entries('all').count
      u.update_column :unread_entries, unread_entries
    end
  end
end
