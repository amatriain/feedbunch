class AddPublishedCreatedAtIdIndexToEntries < ActiveRecord::Migration
  def change
    add_index :entries, [:published, :created_at, :id], name: 'index_entries_on_published_created_at_id',
              order: {published: :desc, created_at: :desc, id: :desc}
  end
end
