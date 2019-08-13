class AddFetchUrlToFeeds < ActiveRecord::Migration[5.2]
  def change
    add_column :feeds, :fetch_url, :text
  end
end
