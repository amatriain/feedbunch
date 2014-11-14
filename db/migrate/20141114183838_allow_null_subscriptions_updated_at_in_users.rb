class AllowNullSubscriptionsUpdatedAtInUsers < ActiveRecord::Migration
  def change
    change_column_null :users, :subscriptions_updated_at, true
  end
end
