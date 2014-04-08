class RenameDataImportStatusToState < ActiveRecord::Migration
  def change
    rename_column :data_imports, :status, :state
  end
end
