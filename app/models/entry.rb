require 'nokogiri'

##
# Feed entry model. Each instance of this class represents an entry in an RSS or Atom feed.
#
# Instances of this class are saved in the database when fetching and parsing feeds. It's not intended to be
# instanced by the user.
#
# Each entry belongs to exactly one feed.
#
# Each entry has many entry-states, exactly one for each user subscribed to the feed. Each entry-state indicates
# whether each user has read or not this entry.
#
# When a new entry is saved in the database for the first time, it is marked as unread for all users subscribed to
# its feed (by saving as many entry_state instances as subscribed users into the database, all of them with the attribute
# "read" set to false).
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
  before_save :links_new_tab
  after_create :set_unread_state

  ##
  # Return a boolean that indicates whether this entry has been marked as read by the passed user.
  #
  # Receives as argument the user for which the read/unread state will be retrieved.

  def read_by?(user)
    state = EntryState.where(entry_id: self.id, user_id: user.id).first
    return state.read
  end

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

  ##
  # For each user subscribed to this entry's feed, save an entry_state instance with the "read" attribute set to false.
  #
  # Or in layman's terms: mark this entry as unread for all users subscribed to the feed.

  def set_unread_state
    self.feed.users.each do |user|
      entry_state = user.entry_states.create({entry_id: self.id, read: false}, as: :admin)
    end
  end

  ##
  # Ensure that any links in the summary open in a new tab, by adding the target="_blank" attribute if necessary

  def links_new_tab
    summaryDoc = Nokogiri::HTML self.summary
    summaryDoc.css('a').each do |link|
      link['target'] = '_blank'
    end
    self.summary = summaryDoc.css('body').children.to_s
  end
end
