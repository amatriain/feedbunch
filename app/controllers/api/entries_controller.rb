require 'etag_calculator'

##
# Controller to access the Feed model.

class Api::EntriesController < ApplicationController

  before_action :authenticate_user!

  respond_to :json

  ##
  # Set an entry state for the current user as read or unread

  def update
    whole_feed = param_str_to_boolean :whole_feed, entry_params
    whole_folder = param_str_to_boolean :whole_folder, entry_params
    all_entries = param_str_to_boolean :all_entries, entry_params

    @entry = current_user.entries.find entry_params[:id]
    current_user.change_entries_state @entry,
                                      entry_params[:state],
                                      whole_feed: whole_feed,
                                      whole_folder: whole_folder,
                                      all_entries: all_entries
    head :ok
  rescue => e
    handle_error e
  end

  ##
  # Return all entries for a given feed or folder.
  #
  # If requesting entries for a feed, the current user must be subscribed. If requesting entries for a folder,
  # it must be owned by the current user.
  #
  # If the "include_read" parameter has the "true" value, return all entries; otherwise return only read ones.
  # If the "folder_id" parameter has the special value "all", all entries for all feeds subscribed by the current
  # user will be returned.

  def index
    @include_read = param_str_to_boolean :include_read, params

    if params[:feed_id].present?
      index_feed
    elsif params[:folder_id].present?
      if params[:folder_id] == Folder::ALL_FOLDERS
        index_all
      else
        index_folder
      end
    else
      Rails.logger.info "User #{current_user.id} - #{current_user.email} requested entries without specifying a folder or feed id, returning a 404"
      head 404
    end
  rescue => e
    handle_error e
  end

  private

  ##
  # Index entries in a feed

  def index_feed
    Rails.logger.debug "User #{current_user.id} - #{current_user.email} requested entries for feed #{params[:feed_id]}, include_read: #{params[:include_read]}"
    @subscription = FeedSubscription.find_by user_id: current_user.id, feed_id: params[:feed_id]
    if @subscription.present?
      # If feed subscription has not changed, return a 304
      if stale? etag: EtagCalculator.etag(@subscription.updated_at),
                last_modified: @subscription.updated_at
        @feed = @subscription.feed
        @entries = current_user.feed_entries @feed, include_read: @include_read, page: params[:page]
        index_entries
      end
    else
      Rails.logger.info "User #{current_user.id} - #{current_user.email} requested entries for feed #{params[:feed_id]} to which he is not subscribed, returning a 404"
      head 404
    end
  end

  ##
  # Index entries in a folder

  def index_folder
    Rails.logger.debug "User #{current_user.id} - #{current_user.email} requested entries for folder #{params[:folder_id]}, include_read: #{params[:include_read]}"
    @folder = current_user.folders.find params[:folder_id]
    # If feed subscriptions in the folder have not changed, return a 304
    if stale? etag: EtagCalculator.etag(@folder.subscriptions_updated_at),
              last_modified: @folder.subscriptions_updated_at
      @entries = current_user.folder_entries @folder, include_read: @include_read, page: params[:page]
      index_entries
    end
  end

  ##
  # Index all entries

  def index_all
    Rails.logger.debug "User #{current_user.id} - #{current_user.email} requested all entries, include_read: #{params[:include_read]}"
    # If feed subscriptions have not changed, return a 304
    if stale? etag: EtagCalculator.etag(current_user.subscriptions_updated_at),
              last_modified: current_user.subscriptions_updated_at
      @folder = Folder::ALL_FOLDERS
      @entries = current_user.folder_entries @folder, include_read: @include_read, page: params[:page]
      index_entries
    end
  end

  ##
  # Index entries previously loaded in an instance variable.
  # Uses an instance variable which must have been previously set:
  # - @entries: entries to index

  def index_entries
    if @entries.present?
      @user = current_user
      respond_with @entries, @user, @include_read
    else
      Rails.logger.info "No entries found for feed_id #{params[:feed_id]} / folder_id #{params[:folder_id]}, returning a 404"
      head 404
    end
  end

  def entry_params
    params.require(:entry).permit(:id, :state, :whole_feed, :whole_folder, :all_entries)
  end
end