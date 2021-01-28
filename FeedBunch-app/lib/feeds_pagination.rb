# frozen_string_literal: true

##
# This class has methods related to retrieving feeds from the database

class FeedsPagination

  ##
  # Retrieve feeds subscribed by the user passed as argument.
  # By default returns only feeds with unread entries, optionally can return all feeds.
  #
  # Receives as arguments:
  # - user subscribed to the feeds.
  # - include_read (optional): boolean that indicates whether to return all feeds
  # (if true) or just feeds withunread entries (if false). By default this argument is false.
  # - page (optional): results page to return.
  #
  # Feeds are ordered by title. If the page argument is nil, all feeds
  # are returned. If it has a value, feeds are paginated and the requested page is returned. Results
  # pagination is achieved with the Kaminari gem, which uses a default page size of 25 results.
  #
  # If successful, returns an ActiveRecord::Relation with the feeds.

  def self.subscribed_feeds(user, include_read: false, page: nil)
    if include_read && !page.present?
      feeds =  user.feeds.order 'title asc'
    elsif include_read && page.present?
      feeds =  user.feeds.order('title asc').page page
    elsif !include_read && !page.present?
      feeds = user.feeds.where('unread_entries > 0').order 'title asc'
    elsif !include_read && page.present?
      feeds = user.feeds.where('unread_entries > 0').order('title asc').page page
    end

    return feeds
  end

end