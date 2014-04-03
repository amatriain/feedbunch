##
# Controller to access the Feed model.

class Api::EntriesController < ApplicationController

  before_filter :authenticate_user!

  respond_to :json

  ##
  # Set an entry state for the current user as read or unread

  def update
    if entry_params[:whole_feed]=='true'
      whole_feed = true
    else
      whole_feed = false
    end

    if entry_params[:whole_folder]=='true'
      whole_folder = true
    else
      whole_folder = false
    end

    if entry_params[:all_entries]=='true'
      all_entries = true
    else
      all_entries = false
    end

    @entry = current_user.entries.find entry_params[:id]
    current_user.change_entries_state @entry,
                                      entry_params[:state],
                                      whole_feed: whole_feed,
                                      whole_folder: whole_folder,
                                      all_entries: all_entries
    head :ok
  rescue => e
    handle_error e
  end

  ##
  # Return all entries for a given feed or folder.
  #
  # If requesting entries for a feed, the current user must be subscribed. If requesting entries for a folder,
  # it must be owned by the current user.
  #
  # If the "include_read" parameter has the "true" value, return all entries; otherwise return only read ones.
  # If the "folder_id" parameter has the special value "all", all entries for all feeds subscribed by the current
  # user will be returned.

  def index
    if params[:include_read]=='true'
      include_read = true
    else
      include_read = false
    end

    if params[:feed_id].present?
      # Request is for feed entries
      Rails.logger.debug "User #{current_user.id} - #{current_user.email} requested entries for feed #{params[:feed_id]}, include_read: #{params[:include_read]}"
      @feed = current_user.feeds.find params[:feed_id]
      @entries = current_user.feed_entries @feed, include_read: include_read, page: params[:page]
    elsif params[:folder_id].present?
      # Request is for folder entries
      Rails.logger.debug "User #{current_user.id} - #{current_user.email} requested entries for folder #{params[:folder_id]}, include_read: #{params[:include_read]}"
      if params[:folder_id] == Folder::ALL_FOLDERS
        @folder = Folder::ALL_FOLDERS
      else
        @folder = current_user.folders.find params[:folder_id]
      end
      @entries = current_user.folder_entries @folder, include_read: include_read, page: params[:page]
    end

    if @entries.present?
      render 'index', locals: {entries: @entries, user: current_user}
    else
      Rails.logger.info "No entries found for feed_id #{params[:feed_id]} / folder_id #{params[:folder_id]}, returning a 404"
      head status: 404
    end
  rescue => e
    handle_error e
  end

  private

  def entry_params
    params.require(:entry).permit(:id, :state, :whole_feed, :whole_folder, :all_entries)
  end
end