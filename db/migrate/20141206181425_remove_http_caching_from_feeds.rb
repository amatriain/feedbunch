class RemoveHttpCachingFromFeeds < ActiveRecord::Migration
  def up
    remove_column :feeds, :etag
    remove_column :feeds, :last_modified
  end

  def down
    add_column :feeds, :etag, :text
    add_column :feeds, :last_modified, :text
  end
end
