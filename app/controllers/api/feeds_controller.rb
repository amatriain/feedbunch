require 'etag_calculator'

##
# Controller to access the Feed model.

class Api::FeedsController < ApplicationController

  before_action :authenticate_user!

  respond_to :json

  ##
  # Return JSON with:
  # - the list of feeds subscribed by the current user, if no :folder_id param is received.
  # - the list of feeds in a folder owned by the current user, if a :folder_id param is received.
  #
  # In both cases the :include_read param controls whether all feeds are returned (if true), or only
  # feeds with unread entries (if false).

  def index
    @include_read = param_str_to_boolean :include_read, params

    if params[:folder_id].present?
      # Retrieve subscribed feeds in the passed folder
      index_folder
    else
      # Retrieve subscribed feeds regardless of folder
      index_all
    end
  rescue => e
    handle_error e
  end

  ##
  # Return a JSON document describing a given feed, as long as the currently authenticated user is suscribed to it.
  #
  # If the requests asks for a feed the current user is not suscribed to, the response is a 404 error code (Not Found).

  def show
    @subscription = FeedSubscription.find_by user_id: current_user.id, feed_id: params[:id]

    if @subscription.present?
      # If feed subscription has not changed, return a 304
      if stale? etag: EtagCalculator.etag(@subscription.updated_at),
                last_modified: @subscription.updated_at
        @feed = current_user.feeds.find params[:id]
        @folder_id = @feed.user_folder(current_user)&.id || 'none'
        @unread_count = current_user.feed_unread_count @feed
        respond_with @feed, @folder_id, @unread_count
      end
    else
      Rails.logger.info "User #{current_user.id} - #{current_user.email} has no feeds to return, returning a 404"
      head 404
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
      head 404
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

  ##
  # Index feeds in a folder

  def index_folder
    @folder = current_user.folders.find params[:folder_id]
    if @folder.present?
      # If feed subscriptions in the folder have not changed, return a 304
      if stale? EtagCalculator.etag(@folder.subscriptions_updated_at),
                last_modified: @folder.subscriptions_updated_at
        @feeds = current_user.folder_feeds @folder, include_read: @include_read
        index_feeds
      end
    else
      Rails.logger.info "User #{current_user.id} - #{current_user.email} tried to index feeds in folder #{params[:folder_id]} which does not exist or he does not own"
      head 404
    end

  end

  ##
  # Index all subscribed feeds, regardless of folder

  def index_all
    # If feed subscriptions have not changed, return a 304
    if stale? etag: EtagCalculator.etag(current_user.subscriptions_updated_at),
              last_modified: current_user.subscriptions_updated_at
      @folder = nil
      @feeds = current_user.subscribed_feeds include_read: @include_read, page: params[:page]
      index_feeds
    end
  end

  ##
  # Index feeds previously loaded in an instance variable.
  # Uses instance variables which must have been previously set:
  # - @feeds: feeds to index
  # - @folder: folder in which all the feeds are; or nil if they are in different folders or they are not in a folder.

  def index_feeds
    if @feeds.present?
      # Compose an array; each element is a hash containing the data necessary to render a feed in the JSON response
      @feeds_data = []
      @feeds.each do |feed|
        begin
          if @folder.nil?
            # If we're retrieving feeds regardless of folder, we have to find out in which folder is each feed, if any.
            folder_id = feed.user_folder(current_user)&.id || 'none'
          else
            # If we're retrieving feeds in a folder, we already know that all feeds are in this folder
            folder_id = @folder.id
          end

          unread_count = current_user.feed_unread_count feed

          data = {feed: feed, folder_id: folder_id, unread_count: unread_count}
          @feeds_data << data
        rescue NotSubscribedError => e
          # If the feed in the current iteration is no longer subscribed (e.g. because of an asynchrously running worker that has
          # unsubscribed it), just ignore it and continue with the next iteration
          Rails.logger.warn "Listing subscribed feeds for user #{current_user.id} - #{current_user.email}, feed #{feed.id} is no longer subscribed, ignoring it"
        end
      end

      respond_with @feeds_data
    else
      Rails.logger.info "User #{current_user.id} - #{current_user.email} has no feeds to return, returning a 404"
      head 404
    end
  end
end
