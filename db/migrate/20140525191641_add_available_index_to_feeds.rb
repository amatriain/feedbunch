class AddAvailableIndexToFeeds < ActiveRecord::Migration
  def change
    add_index :feeds, [:available], name: 'index_feeds_on_available'
  end
end
