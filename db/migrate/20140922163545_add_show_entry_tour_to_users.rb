class AddShowEntryTourToUsers < ActiveRecord::Migration
  def up
    add_column :users, :show_entry_tour, :boolean, default: true, null: true

    User.all.each do |u|
      u.update_column :show_entry_tour, true
    end

    change_column_null :users, :show_entry_tour, false
  end

  def down
    remove_column :users, :show_entry_tour
  end
end
