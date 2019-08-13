class AddEtagAndLastModifiedToFeeds < ActiveRecord::Migration[5.2]
  def change
    add_column :feeds, :etag, :text
    add_column :feeds, :last_modified, :datetime
  end
end
