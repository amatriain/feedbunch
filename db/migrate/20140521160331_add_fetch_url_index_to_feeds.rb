class AddFetchUrlIndexToFeeds < ActiveRecord::Migration
  def change
    add_index :feeds, [:fetch_url], name: 'index_feeds_on_fetch_url'
    add_index :feeds, [:url], name: 'index_feeds_on_url'
  end
end
