class RemoveEmailInvitations < ActiveRecord::Migration[5.2]
  def up
    change_table :users do |t|
      t.remove_references :invited_by, :polymorphic => true
      t.remove :invitation_token, :invitation_created_at, :invitation_sent_at, :invitation_accepted_at, :invitation_limit, :invitations_count,
               :unencrypted_invitation_token, :invitations_count_reset_at
    end

    remove_index :users, name: 'index_users_on_first_invitation_reminder_fields'
    remove_index :users, name: 'index_users_on_second_invitation_reminder_fields'

    change_column_null    :users, :encrypted_password, false
  end

  def down
    change_table :users do |t|
      t.string     :invitation_token
      t.datetime   :invitation_created_at
      t.datetime   :invitation_sent_at
      t.datetime   :invitation_accepted_at
      t.integer    :invitation_limit
      t.references :invited_by, :polymorphic => true
      t.integer    :invitations_count, default: 0
      t.string     :unencrypted_invitation_token
      t.datetime   :invitations_count_reset_at
      t.index      :invitation_token, :unique => true # for invitable
      t.index      :invited_by_id
      t.index      :invitation_limit
      t.index      [:invitations_count, :invitations_count_reset_at], name: 'index_users_on_invitation_count_fields'
      t.remove_index name: 'index_users_on_first_invitation_reminder_fields'
      t.remove_index name: 'index_users_on_second_invitation_reminder_fields'
      t.index      [:invitation_token, :invitation_accepted_at, :invitation_sent_at, :first_confirmation_reminder_sent], name: 'index_users_on_first_invitation_reminder_fields'
      t.index      [:invitation_token, :invitation_accepted_at, :invitation_sent_at, :second_confirmation_reminder_sent], name: 'index_users_on_second_invitation_reminder_fields'
      t.remove_index name: 'index_users_on_first_reminder_fields'
      t.remove_index name: 'index_users_on_second_reminder_fields'
      t.index      [:confirmed_at, :confirmation_sent_at, :first_confirmation_reminder_sent, :invitation_sent_at], name: 'index_users_on_first_reminder_fields'
      t.index      [:confirmed_at, :confirmation_sent_at, :second_confirmation_reminder_sent, :invitation_sent_at], name: 'index_users_on_second_reminder_fields'
    end

    change_column_null :users, :encrypted_password, true
  end
end
