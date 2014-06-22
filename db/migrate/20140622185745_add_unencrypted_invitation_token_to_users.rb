class AddUnencryptedInvitationTokenToUsers < ActiveRecord::Migration
  def change
    add_column :users, :unencrypted_invitation_token, :string
  end
end
