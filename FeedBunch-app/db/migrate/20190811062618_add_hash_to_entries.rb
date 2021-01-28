class AddHashToEntries < ActiveRecord::Migration[5.2]
  def change
    add_column :entries, :content_hash, :text
  end
end
