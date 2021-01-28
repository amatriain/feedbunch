class CreateEntries < ActiveRecord::Migration[5.2]
  def change
    create_table :entries do |t|
      t.text :title
      t.text :url
      t.text :author
      t.text :content
      t.text :summary
      t.datetime :published
      t.text :guid
      t.integer :feed_id
      t.timestamps
    end
  end
end
