##
# Background job to destroy a user. This may trigger other destructions in the database
# (e.g. feeds to which only this user was subscribed).
#
# Its perform method will be invoked from a Resque worker.

class DestroyUserJob
  @queue = :subscriptions

  ##
  # Destroy a user. This may trigger other destructions (see User class).
  #
  # Receives as argument:
  # - id of the user
  #
  # This method is intended to be invoked from Resque, which means it is performed in the background.

  def self.perform(user_id)
    # Check if the user actually exists
    if !User.exists? user_id
      Rails.logger.error "Trying to destroy non-existing user @#{user_id}, aborting job"
      return
    end
    user = User.find user_id

    Rails.logger.info "Destroying user #{user.id} - #{user.email}"
    user.destroy!
  end
end