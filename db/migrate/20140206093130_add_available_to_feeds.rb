class AddAvailableToFeeds < ActiveRecord::Migration
  def change
    add_column :feeds, :available, :boolean, null: false, default: true
  end
end
