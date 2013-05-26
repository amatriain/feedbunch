##
# Controller to access the Feed model.

class EntriesController < ApplicationController
  include ControllersErrorHandling

  before_filter :authenticate_user!

  ##
  # Set an entry state for the current user as read or unread

  def update
    current_user.change_entry_state params[:id], params[:state]
      head status: 200
  rescue => e
    handle_error e
  end
end