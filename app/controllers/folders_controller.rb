##
# Controller to access the Folder model.

class FoldersController < ApplicationController
  before_filter :authenticate_user!

  respond_to :html

  ##
  # Return HTML with all entries for a given folder, containing all feeds subscribed to by the user inside the folder.
  #
  # If the param :id is "all", all entries for all feeds subscribed by the current user will be returned.
  #
  # If the requests asks for a folder that does not belong to the current user, the response is a 404 error code (Not Found).

  def show
    folder_id = params[:id]

    # If asked for folder_id="all", respond with entries of all feeds user is subscribed to
    if folder_id == 'all'
      @entries = current_user.entries
    else
      # If asked for a folder_id, respond with entries for the feeds inside this folder
      @entries = current_user.folders.find(folder_id).entries
    end

    if @entries.present?
      # The folders#show and feeds#show actions use the same template, the only difference is the
      # entries passed to it.
      respond_with @entries, template: 'feeds/show', layout: false
    else
      head status: 404
    end

    return
  rescue ActiveRecord::RecordNotFound
    head status: 404
  end
end
