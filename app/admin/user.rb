ActiveAdmin.register User do
  permit_params :email, :name, :admin

  index do
    selectable_column
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
    default_actions
  end

  filter :email
  filter :name

  form do |f|
    f.inputs 'User Details' do
      f.input :email
      f.input :name
      f.input :admin
    end
    f.actions
  end

  show do
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
    panel 'Feed subscriptions' do
      table_for user.feed_subscriptions do
        column 'title' do |subscription|
          link_to subscription.feed.title, admin_feed_path(subscription.feed)
        end
      end
    end
  end

  sidebar 'User Details', only: [:show, :edit] do
    ul do
      li link_to 'Folders', admin_user_folders_path(user)
    end
  end

end