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
# Each feed, identified by its fetch_url, can be present at most once in the database. Different feeds can have the same
# title, as long as they have different fetch_url.
#
# Attributes of the model:
# - title
# - fetch_url (URL to fetch the feed XML)
# - url (URL to which the user will be linked; usually the website that originated this feed)
#
# Both title and fetch_url are mandatory. url and fetch_url are validated with the following regex:
#   /\Ahttps?:\/\/.+\..+\z/
#
# Title, fetch_url and url are sanitized (with ActionView::Helpers::SanitizeHelper) before validation; this is,
# before saving/updating each instance in the database.

class Feed < ActiveRecord::Base
  include ActionView::Helpers::SanitizeHelper

  attr_accessible :fetch_url

  has_and_belongs_to_many :users
  has_many :entries, dependent: :destroy

  validates :fetch_url, format: {with: /\Ahttps?:\/\/.+\..+\z/}, presence: true, uniqueness: {case_sensitive: false}
  validates :url, format: {with: /\Ahttps?:\/\/.+\..+\z/}, allow_blank: true
  validates :title, presence: true

  before_validation :sanitize_fields

  private

  ##
  # Sanitize the title and URL of the feed.
  #
  # Despite this sanitization happening before saving in the database, sanitize helpers must still be used in the views.
  # Better paranoid than sorry!

  def sanitize_fields
    self.title = sanitize self.title
    self.fetch_url = sanitize self.fetch_url
    self.url = sanitize self.url
  end
end
