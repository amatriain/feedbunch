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
  include SubscriptionHelpers
  include FolderHelpers

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
  # Raises an ActiveRecord;;RecordNotFound error if the folder does not belong to the user.
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

  ##
  # Refresh a folder; this triggers a fetch of all the feeds in the folder.
  #
  # Receives as argument the id of the folder to refresh. The special value "all" means that ALL subscribed feeds
  # will be fetched, regardless of what folder they are in (and even if they are in no folder).
  #
  # Returns an ActiveRecord::Relation with the unread entries for the feeds in the folder; this may or may
  # not contain new entries.
  #
  # If the folder does not belong to the user, an ActiveRecord::RecordNotFound error is raised.

  def refresh_folder(folder_id)
    if folder_id == 'all'
      Rails.logger.info "User #{self.id} - #{self.email} is refreshing all subscribed feeds"
      feeds = self.feeds
    else
      # ensure folder belongs to the user
      folder = self.folders.find folder_id
      Rails.logger.info "User #{self.id} - #{self.email} is refreshing folder #{folder.id} - #{folder.title}"
      feeds = folder.feeds
    end

    feeds.each {|feed| FeedClient.fetch feed.id}
    entries = self.unread_folder_entries folder_id
    return entries
  end

  ##
  # Subscribe the user to a feed. Receives as argument the URL of the feed.
  #
  # First it checks if the feed is already in the database. In this case:
  #
  # - If the user is already subscribed to the feed, an AlreadySubscribedError is raised.
  # - Otherwise, the user is subscribed to the feed. The feed is not fetched (it is assumed its entries are
  # fresh enough).
  #
  # If the feed is not in the database, it checks if the feed can be fetched. If so, the feed is fetched,
  # parsed, saved in the database and the user is subscribed to it.
  #
  # If parsing the fetched response fails, it checks if the URL corresponds to an HTML page with feed autodiscovery
  # enabled. In this case the actual feed is fetched, saved in the database and the user subscribed to it.
  #
  # If the end result is that the user has a new subscription, returns the feed object.
  # If the user is already subscribed to the feed, raises an AlreadySubscribedError.
  # If the user has not been subscribed to a new feed (i.e. because the URL is not valid), returns nil.
  #
  # Note,- When searching for feeds in the database (to see if there is a feed with a matching URL, and whether the
  # user is already subscribed to it), this method is insensitive to trailing slashes, and if no URI-scheme is
  # present an "http://" scheme is assumed.
  #
  # E.g. if the user is subscribed to a feed with url "\http://xkcd.com/", the following URLs would cause an
  # AlreadySubscribedError to be raised:
  #
  # - "\http://xkcd.com/"
  # - "\http://xkcd.com"
  # - "\xkcd.com/"
  # - "\xkcd.com"

  def subscribe(url)
    Rails.logger.info "User #{self.id} - #{self.email} submitted Subscribe form with value #{url}"

    # Ensure the url has a schema (defaults to http:// if none is passed)
    feed_url = ensure_schema url

    # Try to subscribe the user to the feed assuming it's in the database
    feed = subscribe_known_feed self, feed_url

    # If the feed is not in the database, save it and fetch it for the first time.
    if feed.blank?
      feed = subscribe_new_feed self, feed_url
    end

    return feed
  end

  ##
  # Unsubscribes the user from a feed.
  #
  # Receives as argument the id of the feed to unsubscribe.
  #
  # If the user is not subscribed to the feed, an ActiveRecord::RecordNotFound error is raised.
  #
  # If there are no more users subscribed to the feed, it is deleted from the database. This triggers
  # a deletion of all its entries.
  #
  # If the user had associated the feed with a folder, and after unsubscribing there are no more feeds
  # in the folder, that folder is deleted.
  #
  # If successful:
  # - returns the id of the deleted folder,  if the user had associated the feed with a folder and that
  # folder has been deleted (because it had no more feeds inside).
  # - returns nil otherwise (the feed was not in a folder, or the folder still has feeds inside)

  def unsubscribe(feed_id)
    feed = self.feeds.find feed_id
    folder = feed.user_folder self

    Rails.logger.info "unsubscribing user #{self.id} - #{self.email} from feed #{feed.id} - #{feed.fetch_url}"
    self.feeds.delete feed

    if folder.present?
      if !Folder.exists? folder
        deleted_folder_id = folder.id
      end
    end
    return deleted_folder_id
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
