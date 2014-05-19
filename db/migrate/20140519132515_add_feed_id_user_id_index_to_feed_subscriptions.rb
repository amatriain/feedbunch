class AddFeedIdUserIdIndexToFeedSubscriptions < ActiveRecord::Migration
  def change
    add_index :feed_subscriptions, [:feed_id, :user_id], name: 'index_feed_subscriptions_on_feed_id_user_id'
  end
end
