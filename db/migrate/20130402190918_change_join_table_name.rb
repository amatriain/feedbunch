class ChangeJoinTableName < ActiveRecord::Migration[5.2]
  def change
    rename_table :users_feeds, :feeds_users
  end
end
