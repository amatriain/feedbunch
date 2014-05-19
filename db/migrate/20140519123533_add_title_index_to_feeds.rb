class AddTitleIndexToFeeds < ActiveRecord::Migration
  def change
    add_index :feeds, [:title], name: 'index_feeds_on_title'
  end
end
