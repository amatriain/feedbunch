class CreateFolders < ActiveRecord::Migration
  def change
    create_table :folders do |t|
      t.integer :user_id
      t.text :title
      t.timestamps
    end

    create_table :feeds_folders do |t|
      t.integer :feed_id
      t.integer :folder_id
    end
  end
end
