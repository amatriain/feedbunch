class AddInvitationLimitIndexToUsers < ActiveRecord::Migration
  def change
    add_index :users, [:invitation_limit], name: 'index_users_on_invitation_limit'
  end
end
