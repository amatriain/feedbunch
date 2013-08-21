##
# Controller to access the Feed model.

class EntriesController < ApplicationController

  before_filter :authenticate_user!

  ##
  # Set an entry state for the current user as read or unread

  def update
    entries = current_user.entries.find entry_params[:ids]
    changed_data = current_user.change_entries_state entries, entry_params[:state]
    @feeds = changed_data[:feeds]
    @folders = changed_data[:folders]
    render 'update',
           locals: {user: current_user, feeds: @feeds, folders: @folders}
  rescue => e
    handle_error e
  end

  private

  def entry_params
    params.require(:entries).permit({:ids => []}, :state)
  end
end