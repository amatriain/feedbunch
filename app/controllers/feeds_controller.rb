##
# Controller to access the Feed model.

class FeedsController < ApplicationController
  before_filter :authenticate_user!

  respond_to :html, only: [:index, :show, :refresh]
  respond_to :json, only: [:create]

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
      FeedClient.fetch @feed.id
      @feed.reload
      respond_with @feed, layout: false
    end
  end

  ##
  # Subscribe the authenticated user to the feed passed in the params[:subscribe][:rss] param.
  # If successful, return HTML with the entries of the feed.
  #
  # If the param is not the URL of a valid feed, search among known feeds and return HTML with any matches.

  def create
    subscription_success = Feed.subscribe params[:subscription][:rss], current_user.id
    if subscription_success
      #TODO respond with html for successful subscription
    else
      #TODO respond with html for search results
      head status: 404
    end
  end
end
