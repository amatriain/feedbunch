##
# Controller to access the Feed model.

class FeedsController < ApplicationController
  before_filter :authenticate_user!

  respond_to :html

  ##
  # list all feeds the currently authenticated is suscribed to

  def index
    @feeds = current_user.feeds
    respond_with @feeds
  end

  ##
  # return JSON with all entries for a given feed, as long as the currently authenticated user is suscribed to it

  def show
    @feed = current_user.feeds.find params[:id]
    respond_with @feed, layout: false
  end
end
