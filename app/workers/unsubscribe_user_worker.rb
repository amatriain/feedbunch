##
# Background job to unsubscribe a user from a feed
#
# This is a Sidekiq worker

class UnsubscribeUserWorker
  include Sidekiq::Worker

  sidekiq_options queue: :interactive

  ##
  # Unsubscribe a user from a feed
  #
  # Receives as arguments:
  # - id of the user
  # - id of the feed
  #
  # This method is intended to be invoked from Sidekiq, which means it is performed in the background.

  def perform(user_id, feed_id)
    # Check if the user actually exists
    if !User.exists? user_id
      Rails.logger.error "Trying to unsubscribe non-existing user @#{user_id}, aborting job"
      return
    end
    user = User.find user_id

    # Check if the feed actually exists and is subscribed by the user
    if !Feed.exists? feed_id
      Rails.logger.error "Trying to unsubscribe user #{user.id} - #{user.email} from non-existing feed #{feed_id}, aborting job"
      return
    end
    feed = Feed.find feed_id
    if !user.feeds.include? feed
      Rails.logger.error "Trying to unsubscribe user #{user.id} - #{user.email} from feed #{feed.id} - #{feed.title} to which he's not subscribed, aborting job"
      return
    end

    Rails.logger.info "Unsubscribing user #{user.id} - #{user.email} from feed #{feed.id} - #{feed.title}"
    user.unsubscribe feed
  end
end