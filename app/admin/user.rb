ActiveAdmin.register User do
  permit_params :email, :name, :admin

  index do
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

end
