class AddConfirmationIndexToUsers < ActiveRecord::Migration[5.2]
  def change
    add_index :users, [:confirmed_at, :confirmation_sent_at], name: 'index_users_on_confirmation_fields'
  end
end
