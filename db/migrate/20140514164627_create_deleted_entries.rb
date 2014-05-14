class CreateDeletedEntries < ActiveRecord::Migration
  def change
    create_table :deleted_entries do |t|
      t.integer :feed_id, null: false
      t.text :guid, null: false
    end
  end
end
