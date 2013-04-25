##
# Controller to access the Feed model.

class FeedsController < ApplicationController
  before_filter :authenticate_user!

  respond_to :html

  ##
  # list all feeds the currently authenticated is suscribed to

  def index
    @feeds = current_user.feeds
    @folders = current_user.folders
    respond_with @feeds, @folders
  end

  ##
  # Return HTML with all entries for a given feed, as long as the currently authenticated user is suscribed to it.

  def show
    @feed = current_user.feeds.find params[:id]
    if @feed.present?
      respond_with @feed, layout: false
    end
  end

  ##
  # Fetch a feed and save in the database any new entries, as long as the currently authenticated user is suscribed to it.
  #
  # After that it does exactly the same as the show action: return HTML with all entries for the feed

  def refresh
    @feed = current_user.feeds.find params[:id]
    if @feed.present?
      feed_client = FeedClient.new
      feed_client.fetch @feed.id
      @feed.reload
      respond_with @feed, layout: false
    end
  end

  ##
  # Add a subscription to a feed for the currently authenticated user.
  #
  # First it checks if the user wrote the URL of a feed already in the database. If so, the user is subscribed to the feed.
  #
  # Otherwise, it checks if the user wrote a URL which points to a valid feed. If so, the feed is fetched, saved in the database
  # and the user is subscribed to it.
  #
  # Otherwise, it checks if the user wrote the URL of a web page with a feed linked in the header. If the feed is in the
  # database already, the user is subscribed to it; otherwise the feed is fetched, saved in the database and the user
  # subscribed to it.
  #
  # Otherwise, it assumes the user has written a list of search terms, which are searched in the database. If any feeds
  # match, the list of matches is returned to the user so he can choose which one to suscribe to.

  def create
    respond_with nil, layout: false
  end
end
