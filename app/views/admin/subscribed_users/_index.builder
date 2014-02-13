context.instance_eval  do
  h2 'Subscribed users'
  table_for(users, :sortable => true, :class => 'index_table') do |user|
    column do |user|
      link_to 'View', admin_user_path(user)
    end
    column :id
    column :email
    column :name
    column :current_sign_in_at
    column :last_sign_in_at
    column :sign_in_count
    column :admin
    column :locale
    column :timezone
    column :quick_reading
    column :open_all_entries
    column 'Unread entries' do |user|
      user.feed_subscriptions.where(feed_id: feed.id).first.unread_entries
    end
    column do |user|
      link_to 'View', admin_user_path(user)
    end
  end
end