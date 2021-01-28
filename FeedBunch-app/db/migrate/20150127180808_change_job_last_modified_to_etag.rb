class ChangeJobLastModifiedToEtag < ActiveRecord::Migration[5.2]
  def up
    add_column :users, :subscribe_jobs_etag, :text, null: true
    add_column :users, :refresh_feed_jobs_etag, :text, null: true

    User.all.each do |u|
      subscribe_etag = OpenSSL::Digest::MD5.new.hexdigest u.subscribe_jobs_updated_at.to_f.to_s
      u.update_column :subscribe_jobs_etag, subscribe_etag

      refresh_etag = OpenSSL::Digest::MD5.new.hexdigest u.refresh_feed_jobs_updated_at.to_f.to_s
      u.update_column :refresh_feed_jobs_etag, refresh_etag
    end

    remove_column :users, :subscribe_jobs_updated_at
    remove_column :users, :refresh_feed_jobs_updated_at
  end

  def down
    add_column :users, :subscribe_jobs_updated_at, :datetime, null: true
    add_column :users, :refresh_feed_jobs_updated_at, :datetime, null: true

    User.all.each do |u|
      u.update_column :subscribe_jobs_updated_at, Time.zone.now
      u.update_column :refresh_feed_jobs_updated_at, Time.zone.now
    end

    remove_column :users, :subscribe_jobs_etag
    remove_column :users, :refresh_feed_jobs_etag
  end
end
