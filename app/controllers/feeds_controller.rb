##
# Controller to access the Feed model.

class FeedsController < ApplicationController
  before_filter :authenticate_user!

  respond_to :html

  ##
  # list all feeds the currently authenticated is suscribed to

  def index
    @feeds = current_user.feeds
    respond_with @feeds
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
end
