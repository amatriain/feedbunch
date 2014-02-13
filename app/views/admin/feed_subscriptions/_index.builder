context.instance_eval  do
  h2 'Feed subscriptions'
  table_for(feeds, :sortable => true, :class => 'index_table') do |feed_subscription|
    column do |feed|
      link_to 'View', admin_feed_path(feed)
    end
    column :id
    column :title
    column :url
    column :fetch_url
    column :available
    column 'Folder' do |feed|
      if feed.user_folder(user).present?
        link_to feed.user_folder(user).title, "/admin/users/#{user.id}/folders/#{feed.user_folder(user).id}"
      end
    end
    column :last_fetched
    column :fetch_interval_secs
    column :failing_since
    column :etag
    column :last_modified
    column 'Entries' do |feed|
      feed.entries.count
    end
    column 'Unread entries' do |feed|
      user.feed_subscriptions.where(feed_id: feed.id).first.unread_entries
    end
    column do |feed|
      link_to 'View', admin_feed_path(feed)
    end
  end
end