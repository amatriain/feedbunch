class AddQuickReadingToUsers < ActiveRecord::Migration
  def up
    add_column :users, :quick_reading, :boolean

    User.all.each do |u|
      u.update_column :quick_reading, false
    end
  end

  def down
    change_column :users, :quick_reading, :boolean
  end
end
