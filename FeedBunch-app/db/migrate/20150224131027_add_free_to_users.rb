class AddFreeToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :free, :boolean, null: false, default: false
  end
end
