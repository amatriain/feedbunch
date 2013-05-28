##
# Controller to access the Feed model.

class EntriesController < ApplicationController
  include ControllersErrorHandling

  before_filter :authenticate_user!

  ##
  # Set an entry state for the current user as read or unread

  def update
    current_user.change_entry_state params[:entry_ids], params[:state]
    @feed = current_user.feeds.find params[:feed_id]
    @folder= @feed.user_folder current_user
    render 'feeds/show.json.erb',
           locals: {user: current_user, feed: @feed, folder: @folder}
  rescue => e
    handle_error e
  end
end