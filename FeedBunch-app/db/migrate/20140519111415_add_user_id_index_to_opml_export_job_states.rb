class AddUserIdIndexToOpmlExportJobStates < ActiveRecord::Migration[5.2]
  def change
    add_index :opml_export_job_states, [:user_id], name: 'index_opml_export_job_states_on_user_id'
  end
end
