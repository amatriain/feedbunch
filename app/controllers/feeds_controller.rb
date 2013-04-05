##
# Controller to access the Feed model.

class FeedsController < ApplicationController
  before_filter :authenticate_user!
  respond_to :html

  ##
  # list all feeds a user is suscribed to
  def index
    @feeds = Feed.all
    respond_with(@feeds = Feed.all)
  end
end
