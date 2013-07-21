##
# Controller to access the Feed model.

class EntriesController < ApplicationController
  include ControllersErrorHandling

  before_filter :authenticate_user!

  ##
  # Set an entry state for the current user as read or unread

  def update
    changed_data = current_user.change_entry_state params[:entry_ids], params[:state]
    @feeds = changed_data[:feeds]
    @folders = changed_data[:folders]
    render 'update',
           locals: {user: current_user, feeds: @feeds, folders: @folders}
  rescue => e
    handle_error e
  end
end