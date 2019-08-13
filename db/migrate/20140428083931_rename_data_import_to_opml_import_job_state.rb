class RenameDataImportToOpmlImportJobState < ActiveRecord::Migration[5.2]
  def change
    rename_table :data_imports, :opml_import_job_states
  end
end
