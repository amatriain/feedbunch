context.instance_eval  do
  attributes_table do
    row :id
    row :email
    row :name
    row :admin
    row :locale
    row :timezone
    row :quick_reading
    row :open_all_entries
    row :created_at
    row :updated_at
    row :confirmed_at
    row :confirmation_sent_at
    row :reset_password_sent_at
    row :remember_created_at
    row :sign_in_count
    row :current_sign_in_at
    row :last_sign_in_at
    row :current_sign_in_ip
    row :last_sign_in_ip
    row :unconfirmed_email
    row :failed_attempts
    row :locked_at
    row :unlock_token
    row :invited_by_id
    row :invitation_token
    row :invitation_created_at
    row :invitation_sent_at
    row :invitation_accepted_at
    row :invitation_limit
    row :invitations_count
  end

  br

  render 'admin/invitations/index', invitations: user.invitations, context: self

  br

  render 'admin/folders/index', folders: user.folders, context: self

  br

  render 'admin/feed_subscriptions/index', feeds: user.feeds, context: self

  br
  
  active_admin_comments
end