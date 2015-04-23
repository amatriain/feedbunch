class AddSecondConfirmationReminderSentToUsers < ActiveRecord::Migration
  def change
    add_column :users, :second_confirmation_reminder_sent, :boolean, null: false, default: false
    add_index :users, [:confirmed_at, :confirmation_sent_at, :second_confirmation_reminder_sent, :invitation_sent_at], name: 'index_users_on_second_reminder_fields'
  end
end
