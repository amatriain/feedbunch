class AddConfigUpdatedAtToUsers < ActiveRecord::Migration
  def up
    add_column :users, :config_updated_at, :datetime, null: true

    User.all.each do |u|
      u.update_column :config_updated_at, Time.zone.now
    end
  end

  def down
    remove_column :users, :config_updated_at
  end
end
