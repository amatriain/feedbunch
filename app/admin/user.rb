# frozen_string_literal: true

ActiveAdmin.register User do
  permit_params :email, :password, :name, :admin, :locale

  menu priority: 1

  index do
    render 'index', context: self
  end

  filter :id
  filter :email
  filter :name

  before_create do |user|
    user.skip_confirmation!
  end

  form do |f|
    f.inputs 'User Details' do
      f.input :email
      f.input :password
      f.input :name, input_html: {rows: 1}
      f.input :admin
      f.input :locale, as: :select, collection: ['en', 'es'], selected: 'en'
    end
    f.actions
  end

  show do
    render 'show', context: self
  end

end