class ChangeUserDataLastModifiedToEtag < ActiveRecord::Migration[5.2]
  def up
    add_column :users, :user_data_etag, :text, null: true

    User.all.each do |u|
      etag = OpenSSL::Digest::MD5.new.hexdigest u.user_data_updated_at.to_f.to_s
      u.update_column :user_data_etag, etag
    end

    remove_column :users, :user_data_updated_at
  end

  def down
    add_column :users, :user_data_updated_at, :datetime, null: true

    User.all.each do |u|
      u.update_column :user_data_updated_at, Time.zone.now
    end

    remove_column :users, :user_data_etag
  end
end
