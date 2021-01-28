class ChangeSummaryLongtextInEntries < ActiveRecord::Migration[5.2]
  def up
    change_column :entries, :summary, :text, limit: 16777215
  end

  def down
    change_column :entries, :summary, :text
  end
end