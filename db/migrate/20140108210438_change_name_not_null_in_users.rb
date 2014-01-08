class ChangeNameNotNullInUsers < ActiveRecord::Migration
  def up
    change_column :users, :name, :text, null: false
  end

  def down
    change_column :users, :name, :text, null: true
  end
end
