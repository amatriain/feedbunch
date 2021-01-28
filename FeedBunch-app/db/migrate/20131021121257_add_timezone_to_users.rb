class AddTimezoneToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :timezone, :text

    User.all.each do |u|
      u.update_column :timezone, 'UTC'
    end
  end
end
