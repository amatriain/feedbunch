class AddUserIdIndexToFolders < ActiveRecord::Migration[5.2]
  def change
    add_index :folders, [:user_id], name: 'index_folders_on_user_id'
  end
end
