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
  end

  br

  #render 'admin/feed_subscriptions/index', feeds: user.feeds, context: self

  br
  
  active_admin_comments
end