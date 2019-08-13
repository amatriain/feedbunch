class AddUnencryptedInvitationTokenToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :unencrypted_invitation_token, :string
  end
end
