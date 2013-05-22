##
# Module with functions related to subscribing and unsubscribing users from feeds

module SubscriptionHelpers

  ##
  # Ensure that the URL passed as argument has an http:// or https://schema.
  #
  # Receives as argument an URL.
  #
  # If the URL has no schema it is returned prepended with http://
  #
  # If the URL has an http:// or https:// schema, it is returned untouched.

  def ensure_schema(url)
    uri = URI.parse url
    if !uri.kind_of?(URI::HTTP) && !uri.kind_of?(URI::HTTPS)
      Rails.logger.info "Value #{url} has no URI scheme, trying to add http:// scheme"
      fixed_url = URI::HTTP.new('http', nil, url, nil, nil, nil, nil, nil, nil).to_s
    else
      fixed_url = url
    end
    return fixed_url
  end

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

  def subscribe_known_feed(user, feed_url)
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

  def subscribe_new_feed(user, feed_url)
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