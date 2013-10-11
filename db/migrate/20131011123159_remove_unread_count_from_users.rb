class RemoveUnreadCountFromUsers < ActiveRecord::Migration
  def change
    remove_column :users, :unread_entries
  end
end
