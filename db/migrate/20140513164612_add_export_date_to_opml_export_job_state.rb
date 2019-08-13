class AddExportDateToOpmlExportJobState < ActiveRecord::Migration[5.2]
  def change
    add_column :opml_export_job_states, :export_date, :datetime
  end
end
