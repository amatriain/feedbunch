context.instance_eval  do
  attributes_table do
    row 'email'
    row 'name'
    row 'admin'
    row 'locale'
    row 'timezone'
    row 'quick_reading'
    row 'open_all_entries'
    row 'reset_password_sent_at'
    row 'remember_created_at'
    row 'sign_in_count'
    row 'current_sign_in_at'
    row 'last_sign_in_at'
    row 'current_sign_in_ip'
    row 'last_sign_in_ip'
    row 'confirmed_at'
    row 'confirmation_sent_at'
    row 'unconfirmed_email'
    row 'failed_attempts'
    row 'locked_at'
  end

  br

  render 'admin/folders/index', folders: user.folders, context: self

  br

  render 'admin/feed_subscriptions/index', feeds: user.feeds, context: self

  br
  
  active_admin_comments
end