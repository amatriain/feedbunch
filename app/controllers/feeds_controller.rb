##
# Controller to access the Feed model.

class FeedsController < ApplicationController
  before_filter :authenticate_user!
  respond_to :html

  ##
  # list all feeds a user is suscribed to
  def index
    @feeds = current_user.feeds
    respond_with(@feeds)
  end
end
