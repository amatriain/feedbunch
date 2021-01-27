# frozen_string_literal: true

context.instance_eval  do
  table_for(users, :sortable => true, :class => 'index_table') do |folder|
    selectable_column
    actions
    column :id
    column :email
    column :name
    column :admin
    column :locale
    column :timezone
    column :current_sign_in_at
    column :sign_in_count
    actions
  end
end