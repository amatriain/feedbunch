context.instance_eval  do
  table_for(users, :sortable => true, :class => 'index_table') do |folder|
    selectable_column
    actions
    column :id
    column :email
    column :name
    column :admin
    column :free
    column :locale
    column :timezone
    column :quick_reading
    column :open_all_entries
    column :confirmed_at
    column :confirmation_sent_at
    column :invitation_sent_at
    column :invitation_accepted_at
    column :current_sign_in_at
    column :last_sign_in_at
    column :sign_in_count
    actions
  end
end