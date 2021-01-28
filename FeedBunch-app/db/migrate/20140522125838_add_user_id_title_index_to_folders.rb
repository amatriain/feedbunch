class AddUserIdTitleIndexToFolders < ActiveRecord::Migration[5.2]
  def change
    add_index :folders, [:user_id, :title], name: 'index_folders_on_user_id_title'
  end
end
