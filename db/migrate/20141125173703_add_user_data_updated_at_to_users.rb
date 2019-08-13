class AddUserDataUpdatedAtToUsers < ActiveRecord::Migration[5.2]
  def up
    add_column :users, :user_data_updated_at, :datetime, null: true

    User.all.each do |u|
      u.update_column :user_data_updated_at, Time.zone.now
    end
  end

  def down
    remove_column :users, :user_data_updated_at
  end
end
