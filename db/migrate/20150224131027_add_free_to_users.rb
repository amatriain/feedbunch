class AddFreeToUsers < ActiveRecord::Migration
  def change
    add_column :users, :free, :boolean, null: false, default: false
  end
end
