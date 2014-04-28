class RemoveHiddenFromOpmlImportJobStates < ActiveRecord::Migration
  def change
    remove_column :opml_import_job_states, :hidden
  end
end
