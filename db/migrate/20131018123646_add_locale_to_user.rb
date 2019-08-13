class AddLocaleToUser < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :locale, :text

    User.all.each do |u|
      u.update_column :locale, 'en'
    end
  end
end
