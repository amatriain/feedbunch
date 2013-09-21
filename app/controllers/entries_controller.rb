##
# Controller to access the Feed model.

class EntriesController < ApplicationController

  before_filter :authenticate_user!

  ##
  # Set an entry state for the current user as read or unread

  def update
    entries = current_user.entries.find entry_params[:ids]
    current_user.change_entries_state entries, entry_params[:state]
    head :ok
  rescue => e
    handle_error e
  end

  private

  def entry_params
    params.require(:entries).permit({:ids => []}, :state)
  end
end