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

  URL_REGEX = /\Ahttps?:\/\/.+\..+\z/

  belongs_to :feed
  validates :feed_id, presence: true

  has_many :entry_states, -> {uniq}, dependent: :destroy

  validates :title, presence: true
  validates :url, presence: true, format: {with: URL_REGEX}
  validates :guid, presence: true, uniqueness: {case_sensitive: false, scope: :feed_id}

  before_validation :sanitize_attributes
  before_save :content_manipulation
  after_create :set_unread_state

  ##
  # Return a boolean that indicates whether this entry has been marked as read by the passed user.
  #
  # Receives as argument the user for which the read/unread state will be retrieved.
  #
  # If the user is not actually subscribed to the feed, returns false.

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
  #


  def sanitize_attributes
    default_attribute_values
    self.title = sanitize self.title
    self.url = sanitize self.url
    self.author = sanitize self.author
    self.content = sanitize self.content
    self.summary = sanitize self.summary
    self.guid = sanitize self.guid
  end

  ##
  # Give default values to the title and guid attributes if they are empty.
  # Their default value is the value of the "url" attribute.
  #
  # If the url attribute is not a valid URL but the guid is, the url attribute takes
  # the value of the guid attribute. This probably breaks Atom/RSS spec, but I'd like to support feeds
  # that do this.
  #
  # If the publish date is not present, assume the current datetime as default value. This means
  # entries will be shown as published in the moment they are fetched unless the feed specifies
  # otherwise. This ensures all entries have a publish date which avoids major headaches when ordering.

  def default_attribute_values
    # GUID defaults to the url attribute
    self.guid = self.url if self.guid.blank?

    # title defaults to the url attribute
    self.title = self.url if self.title.blank?

    # if the url attr is not actually a valid URL but the guid is, url attr takes the value of the guid attr
    if (self.url =~ URL_REGEX).nil? && self.guid =~ URL_REGEX
      self.url = self.guid
      # If the url was blank before but now has taken the value of the guid, default the title to this value
      self.title = self.url if self.title.blank?
    end

    # published defaults to the current datetime
    self.published = DateTime.now if self.published.blank?
  end

  ##
  # For each user subscribed to this entry's feed, save an entry_state instance with the "read" attribute set to false.
  #
  # Or in layman's terms: mark this entry as unread for all users subscribed to the feed.

  def set_unread_state
    self.feed.users(true).each do |user|
      if !EntryState.exists? user_id: user.id, entry_id: self.id
        entry_state = user.entry_states.create entry_id: self.id, read: false
      end
    end
  end

  ##
  # Manipulations in entries summary and content markup before saving the entry.

  def content_manipulation
    self.summary = markup_manipulation self.summary if self.summary.present?
    self.content = markup_manipulation self.content if self.content.present?
  end

  ##
  # Manipulations in the passed html fragment

  def markup_manipulation(html_fragment)
    html_doc = Nokogiri::HTML html_fragment
    html_doc = add_target_blank html_doc
    html_doc = add_max_width html_doc
    return html_doc.css('body').children.to_s
  end

  ##
  # Add the target="_blank" attribute to any links in the passed HTML fragment.
  # Receives as argument a parsed HTML fragment.
  # The attribute will overwrite any target="" attribute that was present in the links

  def add_target_blank(html_doc)
    html_doc.css('a').each do |link|
      link['target'] = '_blank'
    end
    return html_doc
  end


  ##
  # Remove any height and width attributes and add a CSS max-width:100% to any images
  # in the passed fragment.
  # Receives as argument a parsed HTML fragment.
  # Any style="" attribute in images will be overwritten.

  def add_max_width(html_doc)
    html_doc.css('img').each do |img|
      img['style'] = 'max-width:100%;'
      img.remove_attribute 'height'
      img.remove_attribute 'width'
    end
    return html_doc
  end

end
