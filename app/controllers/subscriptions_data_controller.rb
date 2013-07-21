##
# Controller to import and export subscriptions data

class SubscriptionsDataController < ApplicationController
  include ControllersErrorHandling

  before_filter :authenticate_user!

  respond_to :html, only: [:create]
  respond_to :json, only: [:show]

  ##
  # Return JSON indicating the status of the "import subscriptions" process for the current user

  def show
    render 'show.json.erb', locals: {user: current_user}
  end

  ##
  # Upload a subscriptions data file (probably exported from Google Reader) and subscribe the current user
  # to the feeds there.

  def create
    file = params[:import_subscriptions][:file]
    current_user.import_subscriptions file.tempfile
    redirect_to feeds_path
  rescue => e
    handle_error e
  end

end