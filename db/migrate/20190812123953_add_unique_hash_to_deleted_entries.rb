class AddUniqueHashToDeletedEntries < ActiveRecord::Migration[5.2]
  def change
    add_column :deleted_entries, :unique_hash, :text, null: true
  end
end
