class ChangeJoinTableName < ActiveRecord::Migration
  def change
    rename_table :users_feeds, :feeds_users
  end
end
