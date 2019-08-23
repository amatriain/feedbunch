class ChangeNameNotNullInUsers < ActiveRecord::Migration[5.2]
  def up
    User.where(name: nil).each do |user|
      user.update name: user.email
    end
    change_column :users, :name, :text, null: false
  end

  def down
    change_column :users, :name, :text, null: true
  end
end
