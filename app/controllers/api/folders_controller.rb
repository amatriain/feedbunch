##
# Controller to access the Folder model.

class Api::FoldersController < ApplicationController

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
  # Return a JSON document describing a folder, which must be owned by the current user.
  #
  # If the requests asks for a folder that does not belong to the current user, the response is a 404
  # error code (Not Found).

  def show
    @folder = current_user.folders.find params[:id]

    if @folder.present?
      # If folder has not changed, return a 304
      if stale? @folder
        render 'show', locals: {folder: @folder}
      end
    else
      Rails.logger.info "Folder #{params[:id]} not found, returning a 404"
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
