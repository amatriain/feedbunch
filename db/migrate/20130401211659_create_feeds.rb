class CreateFeeds < ActiveRecord::Migration
  def change
    create_table :feeds do |t|
      t.text :title
      t.text :url
      t.timestamps
    end

    create_table :users_feeds do |t|
      t.integer :user_id
      t.integer :feed_id
    end
  end
end
