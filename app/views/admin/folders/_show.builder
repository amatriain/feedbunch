context.instance_eval  do
  attributes_table do
    row :id
    row :user
    row :title
  end

  br

  render 'admin/feed_subscriptions/index', feeds: folder.feeds, context: self

  br

  active_admin_comments
end