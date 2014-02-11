ActiveAdmin.register Feed do
  permit_params :title, :url, :fetch_url, :available, :fetch_interval_secs

  index do
    column :title
    column :url
    column :fetch_url
    column :available
    column :last_fetched
    column :fetch_interval_secs
    column :failing_since
    column :etag
    column :last_modified
    default_actions
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
  
end
