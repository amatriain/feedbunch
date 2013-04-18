require 'feedzirra'
require 'rest_client'

##
# Feed model. Each instance of this model represents a single feed (Atom, RSS...) to which a user is suscribed.
#
# Many users can be suscribed to a single feed, and a single user can be suscribed to many feeds (many-to-many
# relationship).
#
# Each user can have many entries.
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
#
# Title and URL are sanitized (with ActionView::Helpers::SanitizeHelper) before validation.

class Feed < ActiveRecord::Base
  include ActionView::Helpers::SanitizeHelper

  attr_accessible :url

  has_and_belongs_to_many :users
  has_many :entries, dependent: :destroy

  validates :url, format: {with: /\Ahttps?:\/\/.+\..+\z/}, presence: true, uniqueness: {case_sensitive: false}
  validates :title, presence: true

  # Class to be used for feed downloading. It defaults to RestClient.
  # During unit testing it can be switched with a mock object, so that no actual HTTP calls are made.
  attr_writer :http_client

  before_validation :sanitize_fields

  ##
  # Fetch and return all entries currently in the feed.
  #
  # All fields are sanitized before returning them

  def fetchEntries
    # http_client defaults to RestClient, except if it's already been given another value (which happens
    # during unit testing, in which a mocked is used instead of the real class)
    http_client = @http_client || RestClient
    feed_xml = http_client.get self.url

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

  private

  def sanitize_fields
    self.title = sanitize self.title
    self.url = sanitize self.url
  end
end
