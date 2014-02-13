context.instance_eval  do
  h2 'Folders'
  table_for(folders, :sortable => true, :class => 'index_table') do |folder|
    column :id
    column :title
    column 'Feeds' do |folder|
      folder.feeds.count
    end
    column 'Unread entries' do |folder|
      folder.feeds.to_a.sum {|feed| user.feed_subscriptions.where(feed_id: feed.id).first.unread_entries}
    end
    column do |folder|
      link_to 'View', "/admin/users/#{user.id}/folders/#{folder.id}"
    end
  end
end