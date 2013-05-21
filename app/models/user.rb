##
# User model. Each instance of this class represents a single user that can log in to the application
# (or at least that has passed through the signup process but has not yet confirmed his email).
#
# This class has been created by installing the Devise[https://github.com/plataformatec/devise] gem and
# running the following commands:
#   rails generate devise:install
#   rails generate devise User
#
# The Devise[https://github.com/plataformatec/devise] gem manages authentication in this application. To
# learn more about Devise visit:
# {https://github.com/plataformatec/devise}[https://github.com/plataformatec/devise]
#
# Beyond the attributes added to this class by Devise[https://github.com/plataformatec/devise] for authentication,
# Openreader establishes relationships between the User model and the following models:
#
# - Feed: Each user can be suscribed to many feeds and many users can be suscribed to a single feed (many-to-many relationship).
# - Folder: Each user can have many folders and each folder belongs to a single user (one-to-many relationship).
# - Entry, through the Feed model: This enables us to retrieve all entries for all feeds a user is subscribed to.
# - EntryState: This enables us to retrieve the state (read or unread) of all entries for all feeds a user is subscribed to.
#
# When a user is subscribed to a feed (this is, when a feed is added to the user.feeds array), EntryState instances
# are saved to mark all its entries as unread for this user.
#
# Conversely when a user unsubscribes from a feed (this is, when a feed is removed from the user.feeds array), all
# EntryState instances for its entries and for this user are deleted; the app does not store read/unread state for
# entries that belong to feeds to which the user is not subscribed.
#
# It is not mandatory that a user be suscribed to any feeds (in fact when a user first signs up he won't
# have any suscriptions).

class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :token_authenticatable, :confirmable,
  # :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable,
         :confirmable, :lockable, :timeoutable

  # Setup accessible (or protected) attributes for your model
  attr_accessible :email, :password, :password_confirmation, :remember_me

  has_and_belongs_to_many :feeds, uniq: true, after_add: :mark_unread_entries, after_remove: :remove_entry_states
  has_many :folders, dependent: :destroy, uniq: true
  has_many :entries, through: :feeds
  has_many :entry_states, dependent: :destroy, uniq: true

  ##
  # Retrieve entries from the feed passed as argument that are marked as unread for this user.
  #
  # Receives as argument the id of the feed from which entries are to be retrieved.
  #
  # Returns an ActiveRecord::Relation with the entries if successful.
  #
  # If the user is not subscribed to the feed an ActiveRecord::RecordNotFound error is raised.

  def unread_feed_entries(feed_id)
    # ensure user is subscribed to the feed
    feed = self.feeds.find feed_id

    Rails.logger.info "User #{self.id} - #{self.email} is retrieving unread entries from feed #{feed.id} - #{feed.fetch_url}"
    entries = Entry.joins(:entry_states, :feed).where entry_states: {read: false, user_id: self.id},
                                                      feeds: {id: feed.id}
    return entries
  end

  ##
  # Refresh a feed; this triggers a fetch of the feed from its server.
  #
  # Receives as argument the id of the feed to refresh.
  #
  # Returns an ActiveRecord::Relation with the unread entries for the refreshed feed; this may or may
  # not contain new entries.
  #
  # If the user is not subscribed to the feed an ActiveRecord::RecordNotFound error is raised.

  def refresh_feed(feed_id)
    # ensure user is subscribed to the feed
    feed = self.feeds.find feed_id

    Rails.logger.info "User #{self.id} - #{self.email} is refreshing feed #{feed.id} - #{feed.fetch_url}"
    FeedClient.fetch feed.id
    entries = self.unread_feed_entries feed.id
    return entries
  end

  private

  ##
  # Mark as unread for this user all entries of the feed passed as argument.

  def mark_unread_entries(feed)
    feed.entries.each do |entry|
      self.entry_states.create({entry_id: entry.id, read: false},as: :admin)
    end
  end

  ##
  # Remove al read/unread entry information for this user, for all entries of the feed passed as argument.

  def remove_entry_states(feed)
    feed.entries.each do |entry|
      entry_state = EntryState.where(user_id: self.id, entry_id: entry.id).first
      self.entry_states.delete entry_state
    end
  end
end
