class AddShowAlertToDataImport < ActiveRecord::Migration[5.2]
  def change
    add_column :data_imports, :show_alert, :boolean, null: false, default: true
  end
end
