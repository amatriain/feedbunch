ActiveAdmin.register Folder do
  belongs_to :user
  permit_params :title

  index do
    selectable_column
    column :title
    column :user
    default_actions
  end

  filter :title

  form do |f|
    f.inputs 'Folder Details' do
      f.input :title
    end
    f.actions
  end
end
