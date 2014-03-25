##
# Controller to access the Feed model.

class Api::EntriesController < ApplicationController

  before_filter :authenticate_user!

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

  private

  def entry_params
    params.require(:entry).permit(:id, :state, :whole_feed, :whole_folder, :all_entries)
  end
end