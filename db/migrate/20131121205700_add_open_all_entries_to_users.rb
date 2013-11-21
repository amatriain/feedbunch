class AddOpenAllEntriesToUsers < ActiveRecord::Migration
  def up
    add_column :users, :open_all_entries, :boolean, null: false, default: false

    User.all.each do |u|
      u.update_column :open_all_entries, false
    end
  end

  def down
    change_column :users, :open_all_entries, :boolean
  end
end
