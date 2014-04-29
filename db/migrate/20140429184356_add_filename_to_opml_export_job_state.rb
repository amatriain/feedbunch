class AddFilenameToOpmlExportJobState < ActiveRecord::Migration
  def change
    add_column :opml_export_job_states, :filename, :text
  end
end
