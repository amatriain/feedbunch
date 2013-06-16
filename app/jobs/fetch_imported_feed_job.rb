##
# Background job to fetch for the first time a feed just created as part of an OPML file import.

class FetchImportedFeedJob
  @queue = :update_feeds

  ##
  # Fetch a new feed, just created as part of an OPML file import.
  # When fetch has finished, update the processed feeds count of the data_import for the user that requested the import, so that
  # he can see the import progress
  #
  # Receives as arguments:
  # - the id of the feed to fetch
  # - the id of the user that requested the import
  #
  # This method is intended to be invoked from Resque, which means it is performed in the background.

  def self.perform(feed_id, user_id)
    # Check that user actually exists
    if !User.exists? user_id
      Rails.logger.error "First fetch of imported feed #{feed_id} for user #{user_id} failed because the user doesn't exist"
      return
    end

    user = User.find user_id

    # Check that feed actually exists
    if !Feed.exists? feed_id
      Rails.logger.error "First fetch of imported feed #{feed_id} for user #{user_id} failed because the feed doesn't exist"
      return
    end

    FeedClient.fetch feed_id, true
  ensure
    if user.present?
      # Increment by 1 the number of processed feeds in the import
      user.data_import.processed_feeds += 1

      # If all feeds have been processed, mark the import as finished successfully
      if user.data_import.processed_feeds == user.data_import.total_feeds
        user.data_import.status = DataImport::SUCCESS
      end

      user.data_import.save
    end
  end
end