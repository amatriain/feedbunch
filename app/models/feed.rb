require 'feedzirra'

##
# Feed model. Each instance of this model represents a single feed (Atom, RSS...) to which a user is suscribed.
#
# Many users can be suscribed to a single feed, and a single user can be suscribed to many feeds (many-to-many
# relationship).
#
# Each feed, identified by its URL, can be present at most once in the database. Different feeds can have the same
# title, as long as they have different URLs.
#
# Attributes of the model:
# - title
# - url
#
# Both title and URL are mandatory. URLs are validated with the following regex:
#   /\Ahttps?:\/\/.+\..+\z/

class Feed < ActiveRecord::Base
  include ActionView::Helpers::SanitizeHelper

  attr_accessible :url
  has_and_belongs_to_many :users
  validates :url, format: {with: /\Ahttps?:\/\/.+\..+\z/}, presence: true, uniqueness: {case_sensitive: false}
  validates :title, presence: true

  # Class to be used for feed downloading an parsing. It defaults to Feedzirra::Feed.
  # During unit testing it can be switched with a mock object, so that no actual HTTP calls are made.
  attr_writer :feed_fetcher

  ##
  # Return entries in the feed.
  #
  # All fields are sanitized before returning them

  def entries
    # feed_fetcher defaults to Feedzirra::Feed, except if it's already been given another value (which happens
    # during unit testing)
    feed_fetcher = @feed_fetcher || Feedzirra::Feed
    feed_xml = feed_fetcher.fetch_raw self.url

    # We use the actual Feedzirra::Feed class to parse, never a mock.
    # The motivation behind using a mock for fetching the XML during unit testing is not making HTTP
    # calls during testing, but we can always use the real parser even during testing.
    feed_parsed = Feedzirra::Feed.parse feed_xml
    feed_parsed.sanitize_entries!

    # It seems Feedzirra doesn't sanitize the URL of entries for some reason. It's a field as susceptible of injection
    # as any other, so we sanitize it ourselves
    feed_parsed.entries.each {|entry| entry.url = sanitize entry.url}

    return feed_parsed.entries
  end
end
