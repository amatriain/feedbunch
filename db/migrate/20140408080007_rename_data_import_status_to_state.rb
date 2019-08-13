class RenameDataImportStatusToState < ActiveRecord::Migration[5.2]
  def change
    rename_column :data_imports, :status, :state
  end
end
