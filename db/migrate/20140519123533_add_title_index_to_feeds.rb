class AddTitleIndexToFeeds < ActiveRecord::Migration[5.2]
  def change
    add_index :feeds, [:title], name: 'index_feeds_on_title'
  end
end
