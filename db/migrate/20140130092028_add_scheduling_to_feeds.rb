class AddSchedulingToFeeds < ActiveRecord::Migration
  def change
    add_column :feeds, :last_fetched, :datetime, null: true
    add_column :feeds, :fetch_interval_secs, :integer, null: true
  end
end
