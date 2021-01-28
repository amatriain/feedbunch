class AddFilenameToOpmlExportJobState < ActiveRecord::Migration[5.2]
  def change
    add_column :opml_export_job_states, :filename, :text
  end
end
