class CreateDataImports < ActiveRecord::Migration[5.2]
  def change
    create_table :data_imports do |t|
      t.integer :user_id
      t.text :status
      t.integer :total_feeds
      t.integer :processed_feeds
      t.timestamps
    end
  end
end
