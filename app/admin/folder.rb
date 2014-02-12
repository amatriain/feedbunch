ActiveAdmin.register Folder do
  belongs_to :user
  permit_params :title

  form do |f|
    f.inputs 'Folder Details' do
      f.input :title
    end
    f.actions
  end

  show do
    render 'show', context: self
  end
end
