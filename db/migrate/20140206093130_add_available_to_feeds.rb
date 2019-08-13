class AddAvailableToFeeds < ActiveRecord::Migration[5.2]
  def change
    add_column :feeds, :available, :boolean, null: false, default: true
  end
end
