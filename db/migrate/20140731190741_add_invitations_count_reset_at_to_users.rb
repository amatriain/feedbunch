class AddInvitationsCountResetAtToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :invitations_count_reset_at, :datetime
  end
end
