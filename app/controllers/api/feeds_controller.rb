##
# Controller to access the Feed model.

class Api::FeedsController < ApplicationController

  before_filter :authenticate_user!

  respond_to :json

  ##
  # Return JSON with the list of feeds subscribed by the current user

  def index
    if params[:include_read]=='true'
      include_read = true
    else
      include_read = false
    end
    @feeds = current_user.subscribed_feeds include_read: include_read, page: params[:page]

    if @feeds.present?
      render 'index', locals: {user: current_user, feeds: @feeds}
    else
      Rails.logger.info "User #{current_user.id} - #{current_user.email} has no feeds to return, returning a 404"
      head status: 404
    end
  rescue => e
    handle_error e
  end

  ##
  # Return all entries for a given feed, as long as the currently authenticated user is suscribed to it.
  #
  # If the "include_read" parameter has the "true" value, return all entries; otherwise return only read ones.
  #
  # If the requests asks for a feed the current user is not suscribed to, the response is a 404 error code (Not Found).

  def show
    if params[:include_read]=='true'
      include_read = true
    else
      include_read = false
    end
    @feed = current_user.feeds.find params[:id]
    @entries = current_user.feed_entries @feed, include_read: include_read, page: params[:page]

    if @entries.present?
      render 'show', locals: {feed: @feed, entries: @entries, user: current_user}
    else
      Rails.logger.info "Feed #{params[:id]} has no entries, returning a 404"
      head status: 404
    end
  rescue => e
    handle_error e
  end

  ##
  # Fetch a feed and save in the database any new entries, as long as the currently authenticated user is suscribed to it.
  #
  # If the request asks to refresh a feed the user is not suscribed to, the response is a 404 error code (Not Found).

  def update
    @feed = current_user.feeds.find params[:id]
    current_user.refresh_feed @feed

    head :ok
  rescue => e
    handle_error e
  end

  ##
  # Subscribe the authenticated user to the feed passed in the params[:subscribe][:rss] param.
  # If successful, return JSON containing HTML with the entries of the feed.

  def create
    url = feed_params[:url]
    @feed = current_user.subscribe url

    if @feed.present?
      render 'create', locals: {user: current_user, feed: @feed}
    else
      Rails.logger.error "Could not subscribe user #{current_user.id} to feed #{feed_url}, returning a 404"
      #TODO respond with data for search results, for instance with head status:300 (Multiple Choices)
      head status: 404
    end

  rescue => e
    handle_error e
  end

  ##
  # Unsubscribe the authenticated user from the feed passed in the params[:id] param.

  def destroy
    @feed = Feed.find params[:id]
    current_user.unsubscribe @feed
    head :ok
  rescue => e
    handle_error e
  end

  private

  def feed_params
    params.require(:feed).permit(:url)
  end
end
