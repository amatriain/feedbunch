class CreateOpmlExportJobState < ActiveRecord::Migration[5.2]
  def change
    create_table :opml_export_job_states do |t|
      t.integer :user_id, null: false
      t.text :state, null: false
      t.boolean :show_alert, default: true, null: false
      t.timestamps
    end
  end
end
