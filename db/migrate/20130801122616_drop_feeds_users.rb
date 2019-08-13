class DropFeedsUsers < ActiveRecord::Migration[5.2]
  def up
    drop_table :feeds_users
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
