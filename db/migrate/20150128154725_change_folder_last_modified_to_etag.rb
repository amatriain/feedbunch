class ChangeFolderLastModifiedToEtag < ActiveRecord::Migration
  def up
    add_column :folders, :subscriptions_etag, :text, null: true

    Folder.all.each do |f|
      etag = OpenSSL::Digest::MD5.new.hexdigest f.subscriptions_updated_at.to_f.to_s
      f.update_column :subscriptions_etag, etag
    end

    remove_column :folders, :subscriptions_updated_at
  end

  def down
    add_column :folders, :subscriptions_updated_at, :datetime, null: true

    Folder.all.each do |f|
      f.update_column :subscriptions_updated_at, Time.zone.now
    end

    remove_column :folders, :subscriptions_etag
  end
end
