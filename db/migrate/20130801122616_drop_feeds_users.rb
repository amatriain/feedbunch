class DropFeedsUsers < ActiveRecord::Migration
  def up
    drop_table :feeds_users
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
