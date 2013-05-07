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
  rescue ActiveRecord::RecordNotFound
    head status: 404
  rescue => e
    Rails.logger.error e.message
    Rails.logger.error e.backtrace
    head 500
  end

  ##
  # Return HTML with all entries for a given feed, as long as the currently authenticated user is suscribed to it.
  #
  # If the requests asks for a feed the current user is not suscribed to, the response is a 404 error code (Not Found).

  def show
    @entries = current_user.feeds.find(params[:id]).entries

    if @entries.present?
      respond_with @entries, layout: false
    else
      Rails.logger.warn "Feed #{params[:id]} has no entries or the user is not subscribed to it, returning a 404"
      head status: 404
    end

    return
  rescue ActiveRecord::RecordNotFound
    head status: 404
  rescue => e
    Rails.logger.error e.message
    Rails.logger.error e.backtrace
    head 500
  end

  ##
  # Fetch a feed and save in the database any new entries, as long as the currently authenticated user is suscribed to it.
  #
  # After that it does exactly the same as the show action: return HTML with all entries for the feed.
  #
  # If the request asks to refresh a folder the user is not suscribed to, the response is a 404 error code (Not Found).

  def refresh
    feed = current_user.feeds.find params[:id]
    if feed.present?
      FeedClient.fetch feed.id
      feed.reload
      @entries = feed.entries
      respond_with @entries, template: 'feeds/show', layout: false
    else
      Rails.logger.warn "Feed #{params[:id]} does not belong to the user or does not exist, returning a 404"
      head status: 404
    end
  rescue ActiveRecord::RecordNotFound
    head status: 404
  rescue => e
    Rails.logger.error e.message
    Rails.logger.error e.backtrace
    head 500
  end

  ##
  # Subscribe the authenticated user to the feed passed in the params[:subscribe][:rss] param.
  # If successful, return JSON containing HTML with the entries of the feed.

  def create
    url = params[:subscription][:rss]

    @feed = Feed.subscribe url, current_user.id
    if @feed
      respond_with @feed, layout: false
    else
      Rails.logger.error "Could not subscribe user #{current_user.id} to feed #{feed_url}, returning a 404"
      #TODO respond with html for search results, for instance with head status:300 (Multiple Choices)
      head status: 404
    end

  rescue AlreadySubscribedError
    # If user is already subscribed to the feed, return 304
    head status: 304
  rescue ActiveRecord::RecordNotFound
    # This should not happen normally
    head status: 404
  rescue => e
    Rails.logger.error e.message
    Rails.logger.error e.backtrace
    head 500
  end
end
