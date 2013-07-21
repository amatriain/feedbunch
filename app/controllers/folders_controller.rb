##
# Controller to access the Folder model.

class FoldersController < ApplicationController
  include ControllersErrorHandling

  before_filter :authenticate_user!

  respond_to :html, only: [:show]
  respond_to :json, except: [:show]

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
    @changed_data = current_user.add_feed_to_folder params[:feed_id], params[:id]
    render 'update', locals: {user: current_user,
                                       new_folder: @changed_data[:new_folder],
                                       feed: @changed_data[:feed],
                                       old_folder: @changed_data[:old_folder]}
  rescue => e
    handle_error e
  end

  ##
  # Remove the feed passed in params[:feed_id] from its current folder.

  def remove
    @old_folder = current_user.remove_feed_from_folder params[:feed_id]
    render 'remove', locals: {user: current_user,
                                       old_folder: @old_folder}
  rescue => e
    handle_error e
  end

  ##
  # Create a new folder with the title passed in params[:new_folder_title], and add to it the folder
  # passed in params[:feed_id]

  def create
    @changed_data = current_user.add_feed_to_new_folder params[:new_folder][:feed_id], params[:new_folder][:title]
    render 'create', locals: {user: current_user,
                                       new_folder: @changed_data[:new_folder],
                                       old_folder: @changed_data[:old_folder]}
  rescue => e
    handle_error e
  end

end
