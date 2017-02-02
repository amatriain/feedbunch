class DropDuplicateIndexes < ActiveRecord::Migration[5.0]
  def change
    remove_index :entry_states, name: 'index_entry_states_on_entry_id'
    remove_index :feed_subscriptions, name: 'index_feed_subscriptions_on_feed_id'
    remove_index :feed_subscriptions, name: 'index_feed_subscriptions_on_user_id'
    remove_index :folders, name: 'index_folders_on_user_id'
    remove_index :users, name: 'index_users_on_confirmation_fields'
    remove_index :users, name: 'index_users_on_invitation_fields'
    remove_index :users, name: 'index_users_on_invitations_count'
  end
end
