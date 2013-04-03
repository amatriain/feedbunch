class FeedsController < ApplicationController
  respond_to :html

  # GET /feeds
  def index
    @feeds = Feed.all
    respond_with(@feeds = Feed.all)
  end
end
