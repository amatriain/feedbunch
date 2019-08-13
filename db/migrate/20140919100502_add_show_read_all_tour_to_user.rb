class AddShowReadAllTourToUser < ActiveRecord::Migration[5.2]
  def up
    add_column :users, :show_read_all_tour, :boolean, default: true, null: true

    User.all.each do |u|
      u.update_column :show_read_all_tour, true
    end

    change_column_null :users, :show_read_all_tour, false
  end

  def down
    remove_column :users, :show_read_all_tour
  end
end
