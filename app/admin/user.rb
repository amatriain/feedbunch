ActiveAdmin.register User do
  permit_params :email, :name, :admin

  menu priority: 1

  index do
    render 'index', context: self
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
    render 'show', context: self
  end

end