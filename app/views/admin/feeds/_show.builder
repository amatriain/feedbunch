context.instance_eval  do
  attributes_table do
    row :title
    row :available
    row :url
    row :fetch_url
    row :etag
    row :last_modified
    row :last_fetched
    row :fetch_interval_secs
    row :failing_since
    row 'Entries' do |feed|
      feed.entries.count
    end
  end

  br

  render 'admin/subscribed_users/index', users: feed.users, context: self

  br
  
  active_admin_comments
end