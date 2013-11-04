##
# Controller to access the Folder model.

class FoldersController < ApplicationController

  before_filter :authenticate_user!

  respond_to :html, only: [:show]
  respond_to :json, except: [:show]

  ##
  # Return JSON with the list of folders owned by the current user

  def index
    @folders = current_user.folders
    render 'index', locals: {user: current_user, folders: @folders}
  rescue => e
    handle_error e
  end

  ##
  # Return HTML with all entries for a given folder, containing all feeds subscribed to by the user inside the folder.
  #
  # If the param :id is "all", all entries for all feeds subscribed by the current user will be returned.
  # If the "include_read" parameter has the "true" value, return all entries; otherwise return only read ones.
  #
  # If the requests asks for a folder that does not belong to the current user, the response is a 404 error code (Not Found).

  def show
    if params[:id] == Folder::ALL_FOLDERS
      @folder = Folder::ALL_FOLDERS
    else
      @folder = current_user.folders.find params[:id]
    end

    if params[:include_read]=='true'
      include_read = true
    else
      include_read = false
    end

    @entries = current_user.folder_entries @folder, include_read: include_read, page: params[:page]

    if @entries.present?
      render 'show', locals: {entries: @entries, user: current_user}
    else
      Rails.logger.info "Folder #{params[:id]} has no entries, returning a 404"
      head status: 404
    end
  rescue => e
    handle_error e
  end

  ##
  # Associate a feed with a folder. The current user must own the folder and be subscribed to the feed.

  def update
    @feed = current_user.feeds.find folder_params[:feed_id]
    if params[:id] != Folder::NO_FOLDER
      @folder = current_user.folders.find params[:id]
    else
      @folder = Folder::NO_FOLDER
    end

    current_user.move_feed_to_folder @feed, folder: @folder
    head :ok
  rescue => e
    handle_error e
  end

  ##
  # Create a new folder with the title passed in params[:new_folder_title], and add to it the folder
  # passed in params[:feed_id]

  def create
    @feed = current_user.feeds.find folder_params[:feed_id]
    @folder = current_user.move_feed_to_folder @feed, folder_title: folder_params[:title]
    if @folder.present?
      render 'create', locals: {folder: @folder}
    else
      Rails.logger.error "Could not create folder #{folder_params[:title]} for user #{current_user.id}, returning a 404"
      head status: 404
    end

  rescue => e
    handle_error e
  end

  private

  def folder_params
    params.require(:folder).permit(:feed_id, :title)
  end

end
