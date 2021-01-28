class ChangeUserSubscriptionsLastModifiedToEtag < ActiveRecord::Migration[5.2]
  def up
    add_column :users, :subscriptions_etag, :text, null: true

    User.all.each do |u|
      etag = OpenSSL::Digest::MD5.new.hexdigest u.subscriptions_updated_at.to_f.to_s
      u.update_column :subscriptions_etag, etag
    end

    remove_column :users, :subscriptions_updated_at
  end

  def down
    add_column :users, :subscriptions_updated_at, :datetime, null: true

    User.all.each do |u|
      u.update_column :subscriptions_updated_at, Time.zone.now
    end

    remove_column :users, :subscriptions_etag
  end
end
