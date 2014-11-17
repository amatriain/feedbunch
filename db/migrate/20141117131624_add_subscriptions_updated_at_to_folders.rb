class AddSubscriptionsUpdatedAtToFolders < ActiveRecord::Migration
  def up
    add_column :folders, :subscriptions_updated_at, :datetime, null: true

    Folder.all.each do |u|
      u.update_column :subscriptions_updated_at, Time.zone.now
    end
  end

  def down
    remove_column :folders, :subscriptions_updated_at
  end
end
