##
# Feed entry model. Each instance of this class represents an entry in an RSS or Atom feed.
#
# Instances of this class are saved in the database when fetching and parsing feeds. It's not intended to be
# instanced by the user.
#
# Each entry belongs to exactly one feed.
#
# Each entry has many entry-states, exactly one for each user subscribed to the feed. each entry-state indicates
# whether each user has read or not this entry.
#
# Each entry is uniquely identified by its guid. Duplicate guids are not allowed.
#
# Attributes of the model:
# - title
# - url
# - author
# - content
# - summary
# - published
# - guid
#
# Title, url and guid are mandatory. Urls are validated with this regex:
#   /\Ahttps?:\/\/.+\..+\z/
#
# All fields except "published" are sanitized before validation; this is, before saving/updating each
# instance in the database.

class Entry < ActiveRecord::Base
  include ActionView::Helpers::SanitizeHelper

  attr_accessible #none

  belongs_to :feed
  validates :feed_id, presence: true

  has_many :entry_states, dependent: :destroy, uniq: true

  validates :title, presence: true
  validates :url, presence: true, format: {with: /\Ahttps?:\/\/.+\..+\z/}
  validates :guid, presence: true, uniqueness: {case_sensitive: false}

  before_validation :sanitize_fields

  private

  ##
  # Sanitize the title, url, author, content, summary and guid of the entry.
  #
  # Despite this sanitization happening before saving in the database, sanitize helpers must still be used in the views.
  # Better paranoid than sorry!

  def sanitize_fields
    self.title = sanitize self.title
    self.url = sanitize self.url
    self.author = sanitize self.author
    self.content = sanitize self.content
    self.summary = sanitize self.summary
    self.guid = sanitize self.guid
  end
end
