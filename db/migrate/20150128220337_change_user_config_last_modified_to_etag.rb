class ChangeUserConfigLastModifiedToEtag < ActiveRecord::Migration
  def up
    add_column :users, :config_etag, :text, null: true

    User.all.each do |u|
      etag = OpenSSL::Digest::MD5.new.hexdigest u.config_updated_at.to_f.to_s
      u.update_column :config_etag, etag
    end

    remove_column :users, :config_updated_at
  end

  def down
    add_column :users, :config_updated_at, :datetime, null: true

    User.all.each do |u|
      u.update_column :config_updated_at, Time.zone.now
    end

    remove_column :users, :config_etag
  end
end
