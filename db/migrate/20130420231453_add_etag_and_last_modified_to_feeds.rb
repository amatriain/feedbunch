class AddEtagAndLastModifiedToFeeds < ActiveRecord::Migration
  def change
    add_column :feeds, :etag, :text
    add_column :feeds, :last_modified, :datetime
  end
end
