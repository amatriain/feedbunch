class ChangeContentLongtextInUsers < ActiveRecord::Migration
  def up
    change_column :entries, :content, :text, limit: 16777215
  end

  def down
    change_column :entries, :content, :text
  end
end
