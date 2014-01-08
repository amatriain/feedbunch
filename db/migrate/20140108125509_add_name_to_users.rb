class AddNameToUsers < ActiveRecord::Migration
  def change
    add_column :users, :name, :text, null: true
  end
end
