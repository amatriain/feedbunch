class AllowNullSubscriptionsUpdatedAtInUsers < ActiveRecord::Migration[5.2]
  def change
    change_column_null :users, :subscriptions_updated_at, true
  end
end
