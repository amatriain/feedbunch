class AddShowMainTourToUser < ActiveRecord::Migration[5.2]
  def up
    add_column :users, :show_main_tour, :boolean, default: true, null: true

    User.all.each do |u|
      u.update_column :show_main_tour, true
    end

    change_column_null :users, :show_main_tour, false
  end

  def down
    remove_column :users, :show_main_tour
  end
end
