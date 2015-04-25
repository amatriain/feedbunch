class AddInvitationReminderIndexes < ActiveRecord::Migration
  def change
    add_index :users, [:invitation_token, :invitation_accepted_at, :invitation_sent_at, :first_confirmation_reminder_sent], name: 'index_users_on_first_invitation_reminder_fields'
    add_index :users, [:invitation_token, :invitation_accepted_at, :invitation_sent_at, :second_confirmation_reminder_sent], name: 'index_users_on_second_invitation_reminder_fields'
  end
end
