class CreateFeedSubscriptions < ActiveRecord::Migration
  def change
    create_table :feed_subscriptions do |t|
      t.integer :user_id, null: false
      t.integer :feed_id, null: false
      t.integer :unread_entries

      t.timestamps
    end
  end
end
