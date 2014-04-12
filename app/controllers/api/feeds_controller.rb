##
# Controller to access the Feed model.

class Api::FeedsController < ApplicationController

  before_filter :authenticate_user!

  respond_to :json

  ##
  # Return JSON with:
  # - the list of feeds subscribed by the current user, if no :folder_id param is received.
  # - the list of feeds in a folder owned by the current user, if a :folder_id param is received.
  #
  # In both cases the :include_read param controls whether all feeds are returned (if true), or only
  # feeds with unread entries (if false).

  def index
    if params[:include_read]=='true'
      include_read = true
    else
      include_read = false
    end

    if params[:folder_id].present?
      @folder = current_user.folders.find params[:folder_id]
      @feeds = current_user.folder_feeds @folder, include_read
    else
      @feeds = current_user.subscribed_feeds include_read: include_read, page: params[:page]
    end

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
  # Return a JSON document describing a given feed, as long as the currently authenticated user is suscribed to it.
  #
  # If the requests asks for a feed the current user is not suscribed to, the response is a 404 error code (Not Found).

  def show
    @feed = current_user.feeds.find params[:id]

    if @feed.present?
      render 'show', locals: {feed: @feed, user: current_user}
    else
      Rails.logger.info "Feed #{params[:id]} not found, returning a 404"
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
  # Subscribe the authenticated user to the feed passed in the params[:url] param.

  def create
    feed_url = feed_params[:url]
    @job_state = current_user.enqueue_subscribe_job feed_url

    if @job_state.present?
      head :ok
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
    current_user.enqueue_unsubscribe_job @feed
    head :ok
  rescue => e
    handle_error e
  end

  private

  def feed_params
    params.require(:feed).permit(:url)
  end
end
