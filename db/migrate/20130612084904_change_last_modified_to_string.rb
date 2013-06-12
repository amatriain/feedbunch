class ChangeLastModifiedToString < ActiveRecord::Migration
  def change
    change_column :feeds, :last_modified, :text
  end
end
