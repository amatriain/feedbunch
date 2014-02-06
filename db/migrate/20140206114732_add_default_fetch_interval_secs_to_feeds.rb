class AddDefaultFetchIntervalSecsToFeeds < ActiveRecord::Migration
  def change
    change_column :feeds, :fetch_interval_secs, :integer, null: false, default: 3600
  end
end
