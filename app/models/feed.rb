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
  # During unit testing it can be switched with a mock object.
  attr_writer :feed_reader

  ##
  # Return entries in the feed.
  #
  # All fields are sanitized before returning them

  def entries
    # feed_reader defaults to Feedzirra::Feed, except if it's already been given another value (which happens
    # during unit testing)
    feed_reader = @feed_reader || Feedzirra::Feed

    feed = feed_reader.fetch_and_parse self.url
    feed.sanitize_entries!
    return feed.entries
  end
end
