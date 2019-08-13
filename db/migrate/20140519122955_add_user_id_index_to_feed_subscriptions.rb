class AddUserIdIndexToFeedSubscriptions < ActiveRecord::Migration[5.2]
  def change
    add_index :feed_subscriptions, [:user_id], name: 'index_feed_subscriptions_on_user_id'
  end
end
