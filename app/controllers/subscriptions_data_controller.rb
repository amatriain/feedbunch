##
# Controller to import and export subscriptions data

class SubscriptionsDataController < ApplicationController
  include ControllersErrorHandling

  before_filter :authenticate_user!

  respond_to :html

  ##
  # Upload a subscriptions data file (probably exported from Google Reader) and subscribe the current user
  # to the feeds there.

  def create
    file = params[:import_subscriptions][:file]
    Rails.logger.error "TESTTTT"
  rescue => e
    handle_error e
  end
end