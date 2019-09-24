# frozen_string_literal: true

##
# This class has methods related to retrieving entries from the database

class EntriesPagination

  ##
  # Retrieve entries from the feed passed as argument, that are in the passed state for the passed user.
  #
  # Receives as arguments:
  # - feed from which to retrieve entries.
  # - user for whom the read/unread state of each entry will be considered.
  # - include_read (optional): boolean that indicates whether to include both read and unread entries
  # (if true) or just unread entries (if false). By default this argument is false.
  # - page (optional): results page to return.
  #
  # Entries are ordered by published (first), created_at (second) and id (third). If the page argument
  # is nil, all entries are returned. If it has a value, entries are paginated and the requested page is
  # returned. Results pagination is achieved with the Kaminari gem, which uses a default page size of 25 results.
  #
  # If successful, returns an ActiveRecord::Relation with the entries.

  def self.feed_entries(feed, user, include_read: false, page: nil)
    if include_read && !page.present?
      entries =  feed.entries.order 'entries.published desc, entries.created_at desc, entries.id desc'
    elsif include_read && page.present?
      entries =  feed.entries.order('entries.published desc, entries.created_at desc, entries.id desc').page page
    else
      entries = unread_feed_entries feed, user, page: page
    end

    return entries
  end

  ##
  # Retrieve entries in the folder passed as argument, that are in the passed state for the passed user.
  # In this context, "entries in the folder" means "entries from all feeds in the folder".
  #
  # Receives as arguments:
  # - the folder from which to retrieve entries. The special value
  # "all" means that unread entries should be retrieved from ALL subscribed feeds.
  # - user for whom the read/unread state of each entry will be considered.
  # - include_read (optional): boolean that indicates whether to include both read and unread entries
  # (if true) or just unread entries (if false). By default this argument is false.
  # - page (optional): results page to return.
  #
  # Entries are ordered by published (first), created_at (second) and id (third). If the page argument
  # is nil, all entries are returned. If it has a value, entries are paginated and the requested page is
  # returned. Results pagination is achieved with the Kaminari gem, which uses a default page size of 25 results.
  #
  # If successful, returns an ActiveRecord::Relation with the entries.

  def self.folder_entries(folder, user, include_read: false, page: nil)
    if folder == Folder::ALL_FOLDERS
      if include_read && !page.present?
        entries = user.entries.order 'entries.published desc, entries.created_at desc, entries.id desc'
      elsif include_read && page.present?
        entries = user.entries.order('entries.published desc, entries.created_at desc, entries.id desc').page page
      else
        entries = all_unread_entries user, page: page
      end
    else
      if include_read && !page.present?
        entries = folder.entries.order 'entries.published desc, entries.created_at desc, entries.id desc'
      elsif include_read && page.present?
        entries = folder.entries.order('entries.published desc, entries.created_at desc, entries.id desc').page page
      else
        entries = unread_folder_entries folder, user, page: page
      end
    end

    return entries
  end

  #############################
  # PRIVATE CLASS METHODS
  #############################

  ##
  # Retrieve entries from the feed passed as argument that are marked as unread for the user passed.
  #
  # Receives as arguments:
  # - feed from which entries are to be retrieved
  # - user for which entries are unread.
  # - page (optional): results page to return.
  #
  # Returns an ActiveRecord::Relation with the entries if successful.
  #
  # If the user is not subscribed to the feed an ActiveRecord::RecordNotFound error is raised.

  def self.unread_feed_entries(feed, user, page: nil)
    Rails.logger.info "User #{user.id} - #{user.email} is retrieving unread entries from feed #{feed.id} - #{feed.fetch_url}"
    if page.present?
      entries = Entry.joins(:entry_states, :feed)
                      .where(entry_states: {read: false, user_id: user.id}, feeds: {id: feed.id})
          .order('entry_states.published desc, entry_states.entry_created_at desc, entry_states.entry_id desc, entry_states.read')
                      .page page
    else
      entries = Entry.joins(:entry_states, :feed)
                      .where(entry_states: {read: false, user_id: user.id}, feeds: {id: feed.id})
          .order 'entry_states.published desc, entry_states.entry_created_at desc, entry_states.entry_id desc, entry_states.read'
    end
    return entries
  end
  private_class_method :unread_feed_entries

  ##
  # Retrieve entries from the folder passed as argument that are marked as unread for the user passed.
  #
  # Receives as arguments:
  # - folder from which entries are to be retrieved
  # - user for which entries are unread.
  # - page (optional): results page to return.
  #
  # Returns an ActiveRecord::Relation with the entries if successful.

  def self.unread_folder_entries(folder, user, page: nil)
    Rails.logger.info "User #{user.id} - #{user.email} is retrieving unread entries from folder #{folder.id} - #{folder.title}"
    if page.present?
      entries = Entry.joins(:entry_states, feed: :folders)
                      .where(entry_states: {read: false, user_id: user.id}, folders: {id: folder.id})
          .order('entry_states.published desc, entry_states.entry_created_at desc, entry_states.entry_id desc, entry_states.read')
                      .page page
    else
      entries = Entry.joins(:entry_states, feed: :folders)
                      .where(entry_states: {read: false, user_id: user.id}, folders: {id: folder.id})
          .order 'entry_states.published desc, entry_states.entry_created_at desc, entry_states.entry_id desc, entry_states.read'
    end
    return entries
  end
  private_class_method :unread_folder_entries

  ##
  # Retrieve entries from all subscribed feeds that are marked as unread for the user passed.
  #
  # Receives as arguments:
  # - user for which entries are unread.
  # - page (optional): results page to return.
  #
  # Returns an ActiveRecord::Relation with the entries if successful.

  def self.all_unread_entries(user, page: nil)
    Rails.logger.info "User #{user.id} - #{user.email} is retrieving entries from all subscribed feeds"
    if page.present?
      entries = Entry.joins(:entry_states)
                    .where(entry_states: {read: false, user_id: user.id})
          .order('entry_states.published desc, entry_states.entry_created_at desc, entry_states.entry_id desc, entry_states.read')
                    .page page
    else
      entries = Entry.joins(:entry_states)
                    .where(entry_states: {read: false, user_id: user.id})
          .order 'entry_states.published desc, entry_states.entry_created_at desc, entry_states.entry_id desc, entry_states.read'
    end
    return entries
  end
  private_class_method :all_unread_entries
end
