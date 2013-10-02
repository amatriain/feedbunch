##
# Controller to access the Feed model.

class EntriesController < ApplicationController

  before_filter :authenticate_user!

  ##
  # Set an entry state for the current user as read or unread

  def update
    if entry_params[:update_older]=='true'
      update_older = true
    else
      update_older = false
    end
    @entry = current_user.entries.find entry_params[:id]
    current_user.change_entries_state @entry, entry_params[:state], update_older: update_older
    head :ok
  rescue => e
    handle_error e
  end

  private

  def entry_params
    params.require(:entry).permit(:id, :state, :update_older)
  end
end