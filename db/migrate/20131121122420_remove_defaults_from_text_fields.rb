class RemoveDefaultsFromTextFields < ActiveRecord::Migration
  def up
    # changes to data_imports table
    change_column :data_imports, :status, :text, null: false

    # changes to entries table
    change_column :entries, :title, :text, null: false
    change_column :entries, :url, :text, null: false
    change_column :entries, :guid, :text, null: false

    # changes to feeds table
    change_column :feeds, :title, :text, null: false
    change_column :feeds, :url, :text
    change_column :feeds, :fetch_url, :text, null: false

    # changes to folders table
    change_column :folders, :title, :text, null: false

    # changes to users table
    change_column :users, :locale, :text, null: false
    change_column :users, :timezone, :text, null: false
  end

  def down
    # changes to data_imports table
    change_column :data_imports, :status, :text, null: false, default: DataImport::RUNNING

    # changes to entries table
    change_column :entries, :title, :text, null: false, default: ''
    change_column :entries, :url, :text, null: false, default: 'http://www.feedbunch.com'
    change_column :entries, :guid, :text, null: false, default: ''

    # changes to feeds table
    change_column :feeds, :title, :text, null: false, default: ''
    change_column :feeds, :url, :text, default: 'http://www.feedbunch.com'
    change_column :feeds, :fetch_url, :text, null: false, default: 'http://www.feedbunch.com'

    # changes to folders table
    change_column :folders, :title, :text, null: false, default: ''

    # changes to users table
    change_column :users, :locale, :text, null: false, default: 'en'
    change_column :users, :timezone, :text, null: false, default: 'UTC'
  end
end
