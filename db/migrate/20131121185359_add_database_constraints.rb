class AddDatabaseConstraints < ActiveRecord::Migration[5.2]
  def up
    # changes to data_imports table
    change_column :data_imports, :user_id, :integer, null: false
    change_column :data_imports, :status, :text, null: false
    change_column :data_imports, :total_feeds, :integer, null: false, default: 0
    change_column :data_imports, :processed_feeds, :integer, null: false, default: 0

    # changes to entries table
    change_column :entries, :title, :text, null: false
    change_column :entries, :url, :text, null: false
    change_column :entries, :published, :datetime, null: false
    change_column :entries, :guid, :text, null: false
    change_column :entries, :feed_id, :integer, null: false

    # changes to entry_states table
    change_column :entry_states, :read, :boolean, null: false, default: false
    change_column :entry_states, :user_id, :integer, null: false
    change_column :entry_states, :entry_id, :integer, null: false

    # changes to feed_subscriptions table
    change_column :feed_subscriptions, :user_id, :integer, null: false
    change_column :feed_subscriptions, :feed_id, :integer, null: false
    change_column :feed_subscriptions, :unread_entries, :integer, null: false, default: 0

    # changes to feeds table
    change_column :feeds, :title, :text, null: false
    change_column :feeds, :url, :text
    change_column :feeds, :fetch_url, :text, null: false

    # changes to feeds_folders table
    change_column :feeds_folders, :feed_id, :integer, null: false
    change_column :feeds_folders, :folder_id, :integer, null: false

    # changes to folders table
    change_column :folders, :user_id, :integer, null: false
    change_column :folders, :title, :text, null: false

    # changes to users table
    change_column :users, :locale, :text, null: false
    change_column :users, :timezone, :text, null: false
    change_column :users, :quick_reading, :boolean, null: false, default: false
  end

  def down
    # changes to data_imports table
    change_column :data_imports, :user_id, :integer
    change_column :data_imports, :status, :text
    change_column :data_imports, :total_feeds, :integer
    change_column :data_imports, :processed_feeds, :integer

    # changes to entries table
    change_column :entries, :title, :text
    change_column :entries, :url, :text
    change_column :entries, :published, :datetime
    change_column :entries, :guid, :text
    change_column :entries, :feed_id, :integer

    # changes to entry_states table
    change_column :entry_states, :read, :boolean
    change_column :entry_states, :user_id, :integer
    change_column :entry_states, :entry_id, :integer

    # changes to feed_subscriptions table
    change_column :feed_subscriptions, :user_id, :integer
    change_column :feed_subscriptions, :feed_id, :integer
    change_column :feed_subscriptions, :unread_entries, :integer

    # changes to feeds table
    change_column :feeds, :title, :text
    change_column :feeds, :url, :text
    change_column :feeds, :fetch_url, :text

    # changes to feeds_folders table
    change_column :feeds_folders, :feed_id, :integer
    change_column :feeds_folders, :folder_id, :integer

    # changes to folders table
    change_column :folders, :user_id, :integer
    change_column :folders, :title, :text

    # changes to users table
    change_column :users, :locale, :text
    change_column :users, :timezone, :text
    change_column :users, :quick_reading, :boolean
  end
end