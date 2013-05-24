require 'folder_feed_remove'
require 'folder_feed_add'
require 'feed_subscriber'
require 'feed_unsubscriber'
require 'feed_refresh'

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

  has_and_belongs_to_many :feeds, uniq: true,
                          after_add: :mark_unread_entries,
                          before_remove: :before_remove_feed_subscription,
                          after_remove: :removed_feed_subscription
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
  # Retrieve entries in the folder passed as argument that are marked as unread for this user.
  # In this context, "entries in the folder" means "entries from all feeds in the folder".
  #
  # Receives as argument the id of the folder from which to retrieve entries. The special value
  # "all" means that unread entries should be retrieved from ALL subscribed feeds.
  #
  # Raises an ActiveRecord::RecordNotFound error if the folder does not belong to the user.
  #
  # If successful, returns an ActiveRecord::Relation with the entries.

  def unread_folder_entries(folder_id)
    if folder_id == 'all'
      Rails.logger.info "User #{self.id} - #{self.email} is retrieving unread entries from all subscribed feeds"
      entries = Entry.joins(:entry_states).where entry_states: {read: false, user_id: self.id}
    else
      # ensure folder belongs to user
      folder = self.folders.find folder_id
      Rails.logger.info "User #{self.id} - #{self.email} is retrieving unread entries from folder #{folder.id} - #{folder.title}"
      entries = Entry.joins(:entry_states, feed: :folders).where entry_states: {read: false, user_id: self.id},
                                                                 folders: {id: folder_id}
    end

    return entries
  end

  ##
  # Remove a feed from a folder. See FolderFeedRemove#remove_feed_from_folder

  def remove_feed_from_folder(feed_id)
    FolderFeedRemove.remove_feed_from_folder feed_id, self
  end

  ##
  # Add a feed to an existing folder. See FolderFeedAdd#add_feed_to_folder

  def add_feed_to_folder(feed_id, folder_id)
    FolderFeedAdd.add_feed_to_folder feed_id, folder_id, self
  end

  ##
  # Add a feed to a new folder. See FolderFeedAdd#add_feed_to_new_folder

  def add_feed_to_new_folder(feed_id, folder_title)
    FolderFeedAdd.add_feed_to_new_folder feed_id, folder_title, self
  end

  ##
  # Refresh a single feed. See FeedRefresh#refresh_feed

  def refresh_feed(feed_id)
    FeedRefresh.refresh_feed feed_id, self
  end

  ##
  # Refresh all feeds in a folder. See FeedRefresh#refresh_folder

  def refresh_folder(folder_id)
    FeedRefresh.refresh_folder folder_id, self
  end

  ##
  # Subscribe to a feed. See FeedSubscriber#subscribe

  def subscribe(url)
    FeedSubscriber.subscribe url, self
  end

  ##
  # Unsubscribe from a feed. See FeedUnsubscriber#unsubscribe

  def unsubscribe(feed_id)
    FeedUnsubscriber.unsubscribe feed_id, self
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
  # Before removing a feed subscription, remove the feed from its current folder, if any.
  # If this means the folder is now empty, a deletion of the folder is triggered.

  def before_remove_feed_subscription(feed)
    folder = feed.user_folder self
    folder.feeds.delete feed if folder.present?
  end

  ##
  # When a feed is removed from a user's subscriptions, check if there are other users still subscribed to the feed and:
  # - if there are no subscribed users, delete the feed. This triggers the deletion of all its entries and entry-states.
  # - if there are still users subscribed, delete all entry-states for the user and the feed.

  def removed_feed_subscription(feed)
    if feed.users.blank?
      Rails.logger.warn "no more users subscribed to feed #{feed.id} - #{feed.fetch_url} . Removing it from the database"
      feed.destroy
    else
      remove_entry_states feed
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
