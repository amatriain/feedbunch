##
# Controller to access the Feed model.

class FeedsController < ApplicationController
  include ControllersErrorHandling

  before_filter :authenticate_user!

  respond_to :html, except: [:create, :destroy]
  respond_to :json, only: [:create, :destroy]

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
    @entries = current_user.unread_feed_entries params[:id]

    if @entries.present?
      respond_with @entries, layout: false
    else
      Rails.logger.warn "Feed #{params[:id]} has no entries, returning a 404"
      head status: 404
    end

    return
  rescue => e
    handle_error e
  end

  ##
  # Fetch a feed and save in the database any new entries, as long as the currently authenticated user is suscribed to it.
  #
  # After that it does exactly the same as the show action: return HTML with all entries for the feed.
  #
  # If the request asks to refresh a folder the user is not suscribed to, the response is a 404 error code (Not Found).

  def refresh
    @entries = current_user.refresh_feed params[:id]
    if @entries.present?
      respond_with @entries, template: 'feeds/show', layout: false
    else
      Rails.logger.warn "Feed #{params[:id]} has no entries, returning a 404"
      head status: 404
    end

  rescue => e
    handle_error e
  end

  ##
  # Subscribe the authenticated user to the feed passed in the params[:subscribe][:rss] param.
  # If successful, return JSON containing HTML with the entries of the feed.

  def create
    url = params[:subscription][:rss]
    @feed = current_user.subscribe url

    if @feed.present?
      render 'create.json.erb', locals: {user: current_user, feed: @feed}
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
    @old_folder = current_user.unsubscribe params[:id]
    render 'destroy.json.erb', locals: {user: current_user,
                                       old_folder: @old_folder}
  rescue => e
    handle_error e
  end
end
