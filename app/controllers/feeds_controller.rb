##
# Controller to access the Feed model.

class FeedsController < ApplicationController

  before_filter :authenticate_user!

  respond_to :html, only: [:show, :index]
  respond_to :json, except: [:show, :index]

  ##
  # list all feeds the currently authenticated is suscribed to

  def index
    @feeds = current_user.feeds
    @folders = current_user.folders
    @user = current_user
    respond_with @user, @feeds, @folders
  rescue => e
    handle_error e
  end

  ##
  # Return HTML with all entries for a given feed, as long as the currently authenticated user is suscribed to it.
  #
  # If the requests asks for a feed the current user is not suscribed to, the response is a 404 error code (Not Found).

  def show
    if params[:include_read].present?
      include_read = params[:include_read]
    else
      include_read = false
    end
    @feed = current_user.feeds.find params[:id]
    @entries = current_user.feed_entries @feed, include_read

    if @entries.present?
      render 'entries/index', locals: {entries: @entries, user: current_user}, layout: false
    else
      Rails.logger.warn "Feed #{params[:id]} has no entries, returning a 404"
      head status: 404
    end
  rescue => e
    handle_error e
  end

  ##
  # Fetch a feed and save in the database any new entries, as long as the currently authenticated user is suscribed to it.
  #
  # After that it does exactly the same as the show action: return HTML with all entries for the feed.
  #
  # If the request asks to refresh a feed the user is not suscribed to, the response is a 404 error code (Not Found).

  def update
    @feed = current_user.feeds.find params[:id]
    @folder= @feed.user_folder current_user
    current_user.refresh_feed @feed
    render 'show', locals: {user: current_user, feed: @feed, folder: @folder}
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
      #TODO respond with html for search results, for instance with head status:300 (Multiple Choices)
      head status: 404
    end

  rescue => e
    handle_error e
  end

  ##
  # Unsubscribe the authenticated user from the feed passed in the params[:id] param.

  def destroy
    @feed = Feed.find params[:id]
    @old_folder = current_user.unsubscribe @feed
    render 'destroy', locals: {user: current_user,
                                       old_folder: @old_folder}
  rescue => e
    handle_error e
  end

  private

  def feed_params
    params.require(:feed).permit(:url)
  end
end
