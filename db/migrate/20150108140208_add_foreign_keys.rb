class AddForeignKeys < ActiveRecord::Migration
  def change
    add_foreign_key :deleted_entries, :feeds
    add_foreign_key :entries, :feeds
    add_foreign_key :entry_states, :entries
    add_foreign_key :entry_states, :users
    add_foreign_key :feed_subscriptions, :users
    add_foreign_key :feed_subscriptions, :feeds
    add_foreign_key :feeds_folders, :feeds
    add_foreign_key :feeds_folders, :folders
    add_foreign_key :folders, :users
    add_foreign_key :opml_export_job_states, :users
    add_foreign_key :opml_import_failures, :opml_import_job_states
    add_foreign_key :opml_import_job_states, :users
    add_foreign_key :refresh_feed_job_states, :users
    add_foreign_key :refresh_feed_job_states, :feeds
    add_foreign_key :subscribe_job_states, :users
  end
end
