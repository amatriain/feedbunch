class ChangeSummaryLongtextInEntries < ActiveRecord::Migration
  def up
    change_column :entries, :summary, :text, limit: 16777215
  end

  def down
    change_column :entries, :summary, :text
  end
end