##
# This class has methods to subscribe a user to a feed.

class FeedSubscriber
  extend UriHelpers

  ##
  # Subscribe the user to a feed. Receives as arguments the URL of the feed and the user that will be subscribed.
  #
  # First it checks if the feed is already in the database. In this case:
  #
  # - If the user is already subscribed to the feed, an AlreadySubscribedError is raised.
  # - Otherwise, the user is subscribed to the feed. The feed is not fetched (it is assumed its entries are
  # fresh enough).
  #
  # If the feed is not in the database, it checks if the feed can be fetched. If so, the feed is fetched,
  # parsed, saved in the database and the user is subscribed to it.
  #
  # If parsing the fetched response fails, it checks if the URL corresponds to an HTML page with feed autodiscovery
  # enabled. In this case the actual feed is fetched, saved in the database and the user subscribed to it.
  #
  # If the end result is that the user has a new subscription, returns the feed object.
  # If the user is already subscribed to the feed, raises an AlreadySubscribedError.
  # If the user has not been subscribed to a new feed (i.e. because the URL is not valid), returns nil.
  #
  # Note,- When searching for feeds in the database (to see if there is a feed with a matching URL, and whether the
  # user is already subscribed to it), this method is insensitive to trailing slashes, and if no URI-scheme is
  # present an "http://" scheme is assumed.
  #
  # E.g. if the user is subscribed to a feed with url "\http://xkcd.com/", the following URLs would cause an
  # AlreadySubscribedError to be raised:
  #
  # - "\http://xkcd.com/"
  # - "\http://xkcd.com"
  # - "\xkcd.com/"
  # - "\xkcd.com"

  def self.subscribe(url, user)
    Rails.logger.info "User #{user.id} - #{user.email} submitted Subscribe form with value #{url}"

    # Ensure the url has a schema (defaults to http:// if none is passed)
    feed_url = ensure_schema url

    # Try to subscribe the user to the feed assuming it's in the database
    feed = subscribe_known_feed user, feed_url

    # If the feed is not in the database, save it and fetch it for the first time.
    if feed.blank?
      feed = subscribe_new_feed user, feed_url
    end

    return feed
  end

  private

  ##
  # Subscribe a user to a feed already in the database.
  #
  # Receives as arguments:
  # - the user to subscribe
  # - the URL of the feed. It can match the feed.url (normally the website URL) or the feed.fetch_url
  # (the URL from which the feed is fetched).
  #
  # If the user is already subscribed to the feed, raises an AlreadySubscribedError.
  #
  # If there is no feed in the database matching the passed URL, returns nil.
  #
  # If a matching feed is found, the user is subscribed to it and the feed instance is returned.

  def self.subscribe_known_feed(user, feed_url)
    # Check if there is a feed with that URL already in the database
    known_feed = Feed.url_variants_feed feed_url
    if known_feed.present?
      # Check if the user is already subscribed to the feed
      if user.feeds.include? known_feed
        Rails.logger.info "User #{user.id} (#{user.email}) is already subscribed to feed #{known_feed.id} - #{known_feed.fetch_url}"
        raise AlreadySubscribedError.new
      end
      Rails.logger.info "Subscribing user #{user.id} (#{user.email}) to pre-existing feed #{known_feed.id} - #{known_feed.fetch_url}"
      user.feeds << known_feed
      return known_feed
    else
      return nil
    end
  end

  ##
  # Fetch and save a feed which is not yet in the database, and subscribe a user to it.
  #
  # Receives as argument:
  # - the user to subscribe
  # - the URL of the feed. It may be the URL from which the feed can be directly fetched, or the URL of
  # a website with feed autodiscovery enabled.
  #
  # If the fetch is successful, the feed and its entries are saved in the database, the user is subscribed to the feed
  # and the feed instance is returned.
  #
  # If the fetch is unsuccessful (e.g. no valid feed can be found at the URL), nothing is saved in the database and
  # nil is returned.

  def self.subscribe_new_feed(user, feed_url)
    Rails.logger.info "Feed #{feed_url} not in the database, trying to fetch it"
    feed = Feed.create! fetch_url: feed_url, title: feed_url
    fetch_result = FeedClient.fetch feed.id
    if fetch_result
      Rails.logger.info "New feed #{feed_url} successfully fetched. Subscribing user #{user.id} - #{user.email}"
      # We have to reload the feed because the title has likely changed value to the real one when first fetching it
      feed.reload
      user.feeds << feed
      return feed
    else
      Rails.logger.info "URL #{feed_url} is not a valid feed URL"
      feed.destroy
      return nil
    end
  end
end