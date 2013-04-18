class AddFetchUrlToFeeds < ActiveRecord::Migration
  def change
    add_column :feeds, :fetch_url, :text
  end
end
