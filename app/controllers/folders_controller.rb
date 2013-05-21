##
# Controller to access the Folder model.

class FoldersController < ApplicationController
  before_filter :authenticate_user!

  respond_to :html, except: [:update, :create]
  respond_to :json, only: [:update, :create]

  ##
  # Return HTML with all entries for a given folder, containing all feeds subscribed to by the user inside the folder.
  #
  # If the param :id is "all", all entries for all feeds subscribed by the current user will be returned.
  #
  # If the requests asks for a folder that does not belong to the current user, the response is a 404 error code (Not Found).

  def show
    @entries = current_user.unread_folder_entries params[:id]

    if @entries.present?
      # The folders#show and feeds#show actions use the same template, the only difference is the
      # entries passed to it.
      respond_with @entries, template: 'feeds/show', layout: false
    else
      head status: 404
    end
  rescue => e
    handle_error e
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
  rescue => e
    handle_error e
  end

  ##
  # Associate a feed with a folder. The current user must own the folder and be subscribed to the feed.

  def update
    folder_id = params[:id]
    feed_id = params[:feed_id]

    feed = current_user.feeds.find feed_id
    old_folder = feed.user_folder current_user

    if !current_user.folders.where(id: folder_id).exists?
      Rails.logger.warn "User #{current_user.id} - #{current_user.email} tried to add feed #{feed_id} to folder #{folder_id} that does not belong to him"
      head status: 404
    elsif feed.blank?
      Rails.logger.warn "User #{current_user.id} - #{current_user.email} tried to add folder #{folder_id} to feed #{feed_id} to which he's not subscribed"
      head status: 404
    else
      new_folder = Folder.add_feed folder_id, feed_id
      feed.reload
      # If the feed was in a folder before this change and there are no more feeds in the folder, destroy it.
      if old_folder.present?
        old_folder.reload
        old_folder.destroy if old_folder.feeds.blank?
      end
      render 'update.json.erb', locals: {new_folder: new_folder, feed: feed, old_folder: old_folder}
    end
  rescue => e
    handle_error e
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
  rescue => e
    handle_error e
  end

  ##
  # Create a new folder with the title passed in params[:new_folder_title], and add to it the folder
  # passed in params[:feed_id]

  def create
    params_create = params[:new_folder]
    folder_title = params_create[:title]
    feed_id = params_create[:feed_id]

    feed = current_user.feeds.find feed_id
    old_folder = feed.user_folder current_user

    # Check if current user is subscribed to the folder
    if feed.blank?
      Rails.logger.warn "User #{current_user.id} - #{current_user.email} tried to associate with a new folder feed #{feed_id} to which he is not subscribed"
      head status: 404
    else
      new_folder = Folder.create_user_folder folder_title, current_user.id
      new_folder = Folder.add_feed new_folder.id, feed_id
      # If the feed was in a folder before this change and there are no more feeds in the folder, destroy it.
      if old_folder.present?
        old_folder.reload
        old_folder.destroy if old_folder.feeds.blank?
      end
      render 'create.json.erb', locals: {new_folder: new_folder, old_folder: old_folder}
    end

  rescue => e
    handle_error e
  end

  private

  ##
  # Handle an error raised during action processing.
  # It just logs the error and returns an HTTP 500 or 404 error, depending
  # on the kind of error raised.

  def handle_error(error)
    if error.is_a? ActiveRecord::RecordNotFound
      head status: 404
    elsif error.is_a? AlreadyInFolderError
      # If feed is already associated to the folder, return 304
      head status: 304
    elsif error.is_a? NotInFolderError
      # If feed is not in the folder, return 304
      head status: 304
    elsif error.is_a? FolderAlreadyExistsError
      # If user already has a folder with the same title, return 304
      head status: 304
    else
      Rails.logger.error error.message
      Rails.logger.error error.backtrace
      head status: 500
    end
  end
end
