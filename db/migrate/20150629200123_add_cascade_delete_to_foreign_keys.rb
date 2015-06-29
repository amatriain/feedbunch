class AddCascadeDeleteToForeignKeys < ActiveRecord::Migration
  def change
    remove_foreign_key :deleted_entries, :feeds
    remove_foreign_key :entries, :feeds
    remove_foreign_key :entry_states, :entries
    remove_foreign_key :entry_states, :users
    remove_foreign_key :feed_subscriptions, :users
    remove_foreign_key :feed_subscriptions, :feeds
    remove_foreign_key :feeds_folders, :feeds
    remove_foreign_key :feeds_folders, :folders
    remove_foreign_key :folders, :users
    remove_foreign_key :opml_export_job_states, :users
    remove_foreign_key :opml_import_failures, :opml_import_job_states
    remove_foreign_key :opml_import_job_states, :users
    remove_foreign_key :refresh_feed_job_states, :users
    remove_foreign_key :refresh_feed_job_states, :feeds
    remove_foreign_key :subscribe_job_states, :users

    add_foreign_key :deleted_entries, :feeds, on_delete: :cascade
    add_foreign_key :entries, :feeds, on_delete: :cascade
    add_foreign_key :entry_states, :entries, on_delete: :cascade
    add_foreign_key :entry_states, :users, on_delete: :cascade
    add_foreign_key :feed_subscriptions, :users, on_delete: :cascade
    add_foreign_key :feed_subscriptions, :feeds, on_delete: :cascade
    add_foreign_key :feeds_folders, :feeds, on_delete: :cascade
    add_foreign_key :feeds_folders, :folders, on_delete: :cascade
    add_foreign_key :folders, :users, on_delete: :cascade
    add_foreign_key :opml_export_job_states, :users, on_delete: :cascade
    add_foreign_key :opml_import_failures, :opml_import_job_states, on_delete: :cascade
    add_foreign_key :opml_import_job_states, :users, on_delete: :cascade
    add_foreign_key :refresh_feed_job_states, :users, on_delete: :cascade
    add_foreign_key :refresh_feed_job_states, :feeds, on_delete: :cascade
    add_foreign_key :subscribe_job_states, :users, on_delete: :cascade
  end
end
