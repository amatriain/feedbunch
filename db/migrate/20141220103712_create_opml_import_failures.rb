class CreateOpmlImportFailures < ActiveRecord::Migration[5.2]
  def change
    create_table :opml_import_failures do |t|
      t.integer :opml_import_job_state_id, null: false
      t.text :url, null: false
    end
    add_index :opml_import_failures, [:opml_import_job_state_id], name: 'index_opml_import_failures_on_job_state_id'
  end
end
