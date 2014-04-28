class RenameDataImportToOpmlImportJobState < ActiveRecord::Migration
  def change
    rename_table :data_imports, :opml_import_job_states
  end
end
