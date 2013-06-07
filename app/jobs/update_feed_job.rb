class UpdateFeedJob
  @queue = :update_feeds

  def self.perform(feed_id)
    FeedClient.fetch feed_id
  end
end