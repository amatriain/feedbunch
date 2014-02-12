ActiveAdmin.register Feed do
  permit_params :title, :url, :fetch_url, :available, :fetch_interval_secs

  index do
    render 'index', context: self
  end

  filter :title
  filter :url
  filter :fetch_url
  filter :available

  form do |f|
    f.inputs 'Feed Details' do
      f.input :title
      f.input :url
      f.input :fetch_url
      f.input :available
      f.input :fetch_interval_secs
    end
    f.actions
  end

  show do
    render 'show', context: self
  end
  
end
