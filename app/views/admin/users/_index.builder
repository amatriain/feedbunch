context.instance_eval  do
  table_for(users, :sortable => true, :class => 'index_table') do |folder|
    selectable_column
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
    actions
  end
end