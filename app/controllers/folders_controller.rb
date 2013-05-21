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
    @entries = current_user.refresh_folder params[:id]

    if @entries.present?
      respond_with @entries, template: 'feeds/show', layout: false
    else
      head status: 404
    end
  rescue => e
    handle_error e
  end

  ##
  # Associate a feed with a folder. The current user must own the folder and be subscribed to the feed.

  def update
    changed_data = current_user.add_feed_to_folder params[:feed_id], params[:id]
    render 'update.json.erb', locals: {new_folder: changed_data[:new_folder],
                                       feed: changed_data[:feed], old_folder: changed_data[:old_folder]}
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
        raise StandardError.new
      end
      feed = current_user.feeds.find feed_id
      folder.feeds.delete feed
      folder_still_exists = Folder.exists? id: folder.id
      if folder_still_exists
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
      new_folder.feeds << feed
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
