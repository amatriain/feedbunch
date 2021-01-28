class RemoveUnreadCountFromUsers < ActiveRecord::Migration[5.2]
  def change
    remove_column :users, :unread_entries
  end
end
