class FeedsController < ApplicationController
  respond_to :html

  def index
    @feeds = Feed.all
    respond_with(@feeds = Feed.all)
  end
end
