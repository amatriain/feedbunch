class AddInvitationIndexToUsers < ActiveRecord::Migration[5.2]
  def change
    add_index :users, [:invitation_token, :invitation_accepted_at, :invitation_sent_at], name: 'index_users_on_invitation_fields'
  end
end
