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
  #
  # If the requests asks for a folder that does not belong to the current user, the response is a 404 error code (Not Found).

  def show
    if params[:id] != Folder::ALL_FOLDERS
      @folder = current_user.folders.find params[:id]
    else
      @folder = Folder::ALL_FOLDERS
    end

    @entries = current_user.unread_folder_entries @folder

    if @entries.present?
      # The folders#show and feeds#show actions use the same template, the only difference is the
      # entries passed to it.
      render 'entries/index', locals: {entries: @entries, user: current_user}, layout: false
    else
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
    current_user.move_feed_to_folder @feed, folder_title: folder_params[:title]
    head :ok
  rescue => e
    handle_error e
  end

  private

  def folder_params
    params.require(:folder).permit(:feed_id, :title)
  end

end
