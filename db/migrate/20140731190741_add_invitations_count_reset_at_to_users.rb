class AddInvitationsCountResetAtToUsers < ActiveRecord::Migration
  def change
    add_column :users, :invitations_count_reset_at, :datetime
  end
end
