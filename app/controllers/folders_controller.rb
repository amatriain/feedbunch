##
# Controller to access the Folder model.

class FoldersController < ApplicationController
  before_filter :authenticate_user!

  respond_to :html

  ##
  # Return HTML with all entries for a given folder, containing all feeds subscribed to by the user inside the folder.
  #
  # If the param :id is "all", all entries for all feeds subscribed by the current user will be returned.
  #
  # If the requests asks for a folder that does not belong to the current user, the response is a 404 error code (Not Found).

  def show
    folder_id = params[:id]

    # If asked for folder_id="all", respond with entries of all feeds user is subscribed to
    if folder_id == 'all'
      @entries = current_user.entries
    else
      # If asked for a folder_id, respond with entries for the feeds inside this folder
      @entries = current_user.folders.find(folder_id).entries
    end

    if @entries.present?
      # The folders#show and feeds#show actions use the same template, the only difference is the
      # entries passed to it.
      respond_with @entries, template: 'feeds/show', layout: false
    else
      Rails.logger.warn "No entries found for folder #{params[:id]}, user #{current_user.id}"
      head status: 404
    end

    return
  rescue ActiveRecord::RecordNotFound
    head status: 404
  rescue => e
    Rails.logger.error e.message
    Rails.logger.error e.backtrace
    head status: 500
  end

  ##
  # Fetch all feeds in a folder and save in the database any new entries. User must be subscribed to the feeds.
  #
  # After that it does exactly the same as the show action: return HTML with all entries for a folder, containing
  # all feeds subscribed to by the user inside the folder.
  #
  # If the param :id is "all", all feeds the user is subscribed to will be fetched and their entries returned.
  #
  # If the request asks to refresh a folder that does not belong to the user, the response is an HTTP 404 (Not Found).

  def refresh
    folder_id = params[:id]

    # If asked for folder_id="all", fetch all feeds
    if folder_id == 'all'
      feeds = current_user.feeds
    else
      # If asked for a folder_id, fetch feeds inside the folder
      feeds = current_user.folders.find(folder_id).feeds
    end

    if feeds.present?
      feeds.each { |feed| FeedClient.fetch feed.id if current_user.feeds.include? feed }

      # If asked for folder_id="all", respond with entries of all feeds user is subscribed to
      if folder_id == 'all'
        current_user.reload
        @entries = current_user.entries
      else
        # If asked for a folder_id, respond with entries for the feeds inside this folder
        @entries = current_user.folders.find(folder_id).entries
      end
      respond_with @entries, template: 'feeds/show', layout: false
    else
      Rails.error "Found no feeds to refresh in folder #{params[:id]}, user #{current_user.id}, returning a 404"
      head status: 404
    end
  rescue ActiveRecord::RecordNotFound
    head status: 404
  rescue => e
    Rails.logger.error e.message
    Rails.logger.error e.backtrace
    head status: 500
  end

  ##
  # Associate a feed with a folder. The current user must own the folder and be subscribed to the feed.

  def update
    folder_id = params[:id]
    feed_id = params[:feed_id]

    if !current_user.folders.where(id: folder_id).exists?
      Rails.logger.warn "User #{current_user.id} - #{current_user.email} tried to add feed #{feed_id} to folder #{folder_id} that does not belong to him"
      head status: 404
    elsif !current_user.feeds.where(id: feed_id).exists?
      Rails.logger.warn "User #{current_user.id} - #{current_user.email} tried to add folder #{folder_id} to feed #{feed_id} to which he's not subscribed"
      head status: 404
    else
      @folder = Folder.add_feed folder_id, feed_id
      render 'feeds/_sidebar_feed', locals: {feed: Feed.find(feed_id)}, layout: false
    end
  rescue AlreadyInFolderError
    # If feed is already associated to the folder, return 304
    head status: 304
  rescue ActiveRecord::RecordNotFound
    head status: 404
  rescue => e
    Rails.logger.error e.message
    Rails.logger.error e.backtrace
    head status: 500
  end

  ##
  # Remove the feed passed in params[:feed_id] from its current folder.

  def remove
    feed_id = params[:feed_id]

    if !current_user.feeds.where(id: feed_id).exists?
      Rails.logger.warn "User #{current_user.id} - #{current_user.email} tried to remove feed #{feed_id} to which he's not subscribed from folders"
      head status: 404
    else
      folder = Feed.find(feed_id).folders.where(user_id: current_user.id).first
      if folder.blank?
        raise NotInFolderError.new
      end
      folder_has_feeds = Folder.remove_feed folder.id, feed_id
      if folder_has_feeds
        head status: 204
      else
        head status: 205
      end
    end
  rescue NotInFolderError
    # If feed is not in the folder, return 304
    head status: 304
  rescue ActiveRecord::RecordNotFound
    head status: 404
  rescue => e
    Rails.logger.error e.message
    Rails.logger.error e.backtrace
    head status: 500
  end

  ##
  # Create a new folder with the title passed in params[:new_folder_title], and add to it the folder
  # passed in params[:feed_id]

  def create
    folder = Folder.create_user_folder params[:new_folder_title], current_user.id
    folder = Folder.add_feed folder.id, params[:feed_id]
    render 'feeds/_sidebar_folder', locals: {feeds: folder.feeds, title: folder.title, folder_id: folder.id}, layout: false
  rescue FolderAlreadyExistsError
    # If user already has a folder with the same title, return 304
    head status: 304
  rescue ActiveRecord::RecordNotFound
    head status: 404
  rescue => e
    Rails.logger.error e.message
    Rails.logger.error e.backtrace
    head status: 500
  end
end
