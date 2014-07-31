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
    row 'OPML import state' do |user|
      user.opml_import_job_state.state
    end
    row 'OPML import date' do |user|
      user.opml_import_job_state.updated_at
    end
    row 'OPML export state' do |user|
      user.opml_export_job_state.state
    end
    row 'OPML export date' do |user|
      user.opml_export_job_state.updated_at
    end
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
    row :invitations_count_reset_at
  end

  br

  render 'admin/invitations/index', invitations: user.invitations, context: self

  br

  render 'admin/subscribe_jobs/index', jobs: user.subscribe_job_states, context: self


  br

  render 'admin/refresh_feed_jobs/index', jobs: user.refresh_feed_job_states, context: self

  br

  render 'admin/folders/index', folders: user.folders, context: self

  br

  render 'admin/feed_subscriptions/index', feeds: user.feeds, context: self

  br
  
  active_admin_comments
end