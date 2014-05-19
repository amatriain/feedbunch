class AddFeedIdIndexToFeedSubscriptions < ActiveRecord::Migration
  def change
    add_index :feed_subscriptions, [:feed_id], name: 'index_feed_subscriptions_on_feed_id'
  end
end
