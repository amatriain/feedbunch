class AddInvitationsCountResetIndexToUsers < ActiveRecord::Migration
  def change
    add_index :users, [:invitations_count, :invitations_count_reset_at], name: 'index_users_on_invitation_count_fields'
  end
end
