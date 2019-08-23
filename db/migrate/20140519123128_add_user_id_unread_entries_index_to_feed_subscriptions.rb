class AddUserIdUnreadEntriesIndexToFeedSubscriptions < ActiveRecord::Migration[5.2]
  def change
    add_index :feed_subscriptions, [:user_id, :unread_entries], name: 'index_feed_subscriptions_on_user_id_unread_entries'
  end
end
