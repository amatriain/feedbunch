class AddSubscriptionsUpdatedAtToUsers < ActiveRecord::Migration[5.2]
  def up
    add_column :users, :subscriptions_updated_at, :datetime, null: true

    User.all.each do |u|
      u.update_column :subscriptions_updated_at, Time.zone.now
    end

    change_column_null :users, :subscriptions_updated_at, false
  end

  def down
    remove_column :users, :subscriptions_updated_at
  end
end
