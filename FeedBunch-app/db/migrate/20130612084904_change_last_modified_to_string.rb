class ChangeLastModifiedToString < ActiveRecord::Migration[5.2]
  def change
    change_column :feeds, :last_modified, :text
  end
end
