class RemoveFreeFromUsers < ActiveRecord::Migration[6.0]
  def up
    remove_column :users, :free
  end

  def down
    add_column :users, :free, :boolean, null: false, default: false
  end
end
