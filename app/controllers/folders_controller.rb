##
# Controller to access the Folder model.

class FoldersController < ApplicationController
  include ControllersErrorHandling

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
    @changed_data = current_user.add_feed_to_folder params[:feed_id], params[:id]
    render 'update.json.erb', locals: {user: current_user,
                                       new_folder: @changed_data[:new_folder],
                                       feed: @changed_data[:feed],
                                       old_folder: @changed_data[:old_folder]}
  rescue => e
    handle_error e
  end

  ##
  # Remove the feed passed in params[:feed_id] from its current folder.

  def remove
    folder_still_exists = current_user.remove_feed_from_folder params[:feed_id]
    if folder_still_exists
      head status: 204
    else
      head status: 205
    end
  rescue => e
    handle_error e
  end

  ##
  # Create a new folder with the title passed in params[:new_folder_title], and add to it the folder
  # passed in params[:feed_id]

  def create
    @changed_data = current_user.add_feed_to_new_folder params[:new_folder][:feed_id], params[:new_folder][:title]
    render 'create.json.erb', locals: {user: current_user,
                                       new_folder: @changed_data[:new_folder],
                                       old_folder: @changed_data[:old_folder]}
  rescue => e
    handle_error e
  end

end
