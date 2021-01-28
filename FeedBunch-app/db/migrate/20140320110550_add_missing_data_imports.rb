class AddMissingDataImports < ActiveRecord::Migration[5.2]
  def up
    User.all.each do |user|
      user.create_data_import status: DataImport::NONE if user.data_import.blank?
    end
  end

  def down
    DataImport.destroy_all status: DataImport::NONE
  end
end
