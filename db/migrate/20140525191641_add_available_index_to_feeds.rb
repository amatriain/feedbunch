class AddAvailableIndexToFeeds < ActiveRecord::Migration[5.2]
  def change
    add_index :feeds, [:available], name: 'index_feeds_on_available'
  end
end
