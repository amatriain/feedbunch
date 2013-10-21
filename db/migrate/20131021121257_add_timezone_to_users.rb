class AddTimezoneToUsers < ActiveRecord::Migration
  def change
    add_column :users, :timezone, :text

    User.all.each do |u|
      u.update_column :timezone, 'UTC'
    end
  end
end
