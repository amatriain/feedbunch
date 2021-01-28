class NotNullTimestamps < ActiveRecord::Migration[5.2]
  def change
    change_column_null :active_admin_comments, :created_at, false, Time.zone.now
    change_column_null :active_admin_comments, :updated_at, false

    add_timestamps :deleted_entries, null: true
    change_column_null :deleted_entries, :created_at, false, Time.zone.now
    change_column_null :deleted_entries, :updated_at, false, Time.zone.now

    change_column_null :entries, :created_at, false, Time.zone.now
    change_column_null :entries, :updated_at, false, Time.zone.now

    change_column_null :entry_states, :created_at, false, Time.zone.now
    change_column_null :entry_states, :updated_at, false, Time.zone.now

    change_column_null :feed_subscriptions, :created_at, false, Time.zone.now
    change_column_null :feed_subscriptions, :updated_at, false, Time.zone.now

    change_column_null :feeds, :created_at, false, Time.zone.now
    change_column_null :feeds, :updated_at, false, Time.zone.now

    add_timestamps :feeds_folders, null: true
    change_column_null :feeds_folders, :created_at, false, Time.zone.now
    change_column_null :feeds_folders, :updated_at, false, Time.zone.now

    change_column_null :folders, :created_at, false, Time.zone.now
    change_column_null :folders, :updated_at, false, Time.zone.now

    change_column_null :opml_export_job_states, :created_at, false, Time.zone.now
    change_column_null :opml_export_job_states, :updated_at, false, Time.zone.now

    add_timestamps :opml_import_failures, null: true
    change_column_null :opml_import_failures, :created_at, false, Time.zone.now
    change_column_null :opml_import_failures, :updated_at, false, Time.zone.now

    change_column_null :opml_import_job_states, :created_at, false, Time.zone.now
    change_column_null :opml_import_job_states, :updated_at, false, Time.zone.now

    change_column_null :refresh_feed_job_states, :created_at, false, Time.zone.now
    change_column_null :refresh_feed_job_states, :updated_at, false, Time.zone.now

    change_column_null :subscribe_job_states, :created_at, false, Time.zone.now
    change_column_null :subscribe_job_states, :updated_at, false, Time.zone.now

    change_column_null :users, :created_at, false, Time.zone.now
    change_column_null :users, :updated_at, false, Time.zone.now
  end
end
