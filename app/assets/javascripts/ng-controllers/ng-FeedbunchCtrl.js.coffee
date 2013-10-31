########################################################
# AngularJS controller file
########################################################

angular.module('feedbunch').controller 'FeedbunchCtrl',
['$rootScope', '$scope', 'feedsFoldersSvc', 'importStatusSvc', 'timerFlagSvc',
'currentFeedSvc', 'currentFolderSvc', 'subscriptionSvc', 'readSvc', 'folderSvc', 'entrySvc', 'entriesPaginationSvc',
'findSvc',
($rootScope, $scope, feedsFoldersSvc, importStatusSvc, timerFlagSvc,
currentFeedSvc, currentFolderSvc, subscriptionSvc, readSvc, folderSvc, entrySvc, entriesPaginationSvc,
findSvc)->

  # Show Add Subscription button in this view
  $rootScope.show_feed_buttons = true

  # Load folders and feeds via AJAX on startup
  feedsFoldersSvc.load_data()

  # Load status of data import process for the current user
  importStatusSvc.load_data false

  # If there is a rails alert, show it and close it after 5 seconds
  timerFlagSvc.start 'error_rails'

  #--------------------------------------------
  # Show the start page
  #--------------------------------------------
  $scope.show_start_page = ->
    currentFeedSvc.unset()
    currentFolderSvc.unset()
    entriesPaginationSvc.set_busy false

  #--------------------------------------------
  # Unsubscribe from a feed
  #--------------------------------------------
  $scope.unsubscribe = ->
    subscriptionSvc.unsubscribe()

  #--------------------------------------------
  # Subscribe to a feed
  #--------------------------------------------
  $scope.subscribe = ->
    $("#subscribe-feed-popup").modal 'hide'
    subscriptionSvc.subscribe $scope.subscription_url
    $scope.subscription_url = null

  #--------------------------------------------
  # Reload feeds. Receives a boolean argument to indicate if
  # we want to load all feeds (true) or only feeds with unread entries (false).
  #--------------------------------------------
  $scope.load_feeds = (include_read)->
    feedsFoldersSvc.load_feeds include_read

  #--------------------------------------------
  # Remove a feed from a folder
  #--------------------------------------------
  $scope.remove_from_folder = ->
    folderSvc.remove_from_folder()

  #--------------------------------------------
  # Move a feed to an already existing folder
  #--------------------------------------------
  $scope.move_to_folder = (folder)->
    folderSvc.move_to_folder folder

  #--------------------------------------------
  # Move a feed to a new folder
  #--------------------------------------------
  $scope.move_to_new_folder = ()->
    $("#new-folder-popup").modal 'hide'
    folderSvc.move_to_new_folder $scope.new_folder_title
    $scope.new_folder_title = null

  #--------------------------------------------
  # Set the currently selected feed
  #--------------------------------------------
  $scope.set_current_feed = (feed)->
    currentFeedSvc.set feed
    readSvc.read_entries_page()

  #--------------------------------------------
  # Set the currently selected folder
  #--------------------------------------------
  $scope.set_current_folder = (folder)->
    currentFolderSvc.set folder
    readSvc.read_entries_page()

  #--------------------------------------------
  # Load a page of entries for the currently selected feed or folder
  #--------------------------------------------
  $scope.read_entries_page = ()->
    readSvc.read_entries_page()

  #--------------------------------------------
  # Load all of a feed's entries regardless of state
  #--------------------------------------------
  $scope.read_all_entries = ->
    readSvc.read_feed_all()

  #--------------------------------------------
  # Refresh a feed and load its unread entries
  #--------------------------------------------
  $scope.refresh_feed = ->
    readSvc.refresh_feed()

  #--------------------------------------------
  # Mark a single folder as open in the scope
  #--------------------------------------------
  $scope.open_folder = (folder)->
    readSvc.open_folder folder

  #--------------------------------------------
  # Mark a single entry as read
  #--------------------------------------------
  $scope.read_entry = (entry)->
    entrySvc.read_entry entry

  #--------------------------------------------
  # Mark all entries as read
  #--------------------------------------------
  $scope.mark_all_read = ->
    entrySvc.mark_all_read()

  #--------------------------------------------
  # Mark a single entry as unread
  #--------------------------------------------
  $scope.unread_entry = ->
    entrySvc.unread_entry()

  #--------------------------------------------
  # Set a boolean flag in the root scope as false. The flag name must be passed as a string.
  # This is used to hide alerts when clicking on their X button.
  #--------------------------------------------
  $scope.reset_flag = (flag)->
    timerFlagSvc.reset flag

  #--------------------------------------------
  # Count the number of unread entries in a folder
  #--------------------------------------------
  $scope.folder_unread_entries = (folder)->
    feedsFoldersSvc.folder_unread_entries folder

  #--------------------------------------------
  # Count the total number of unread entries in feeds
  #--------------------------------------------
  $scope.total_unread_entries = ->
    feedsFoldersSvc.total_unread_entries()

  #--------------------------------------------
  # Function to filter feeds in a given folder
  #--------------------------------------------
  $scope.feed_in_folder = (folder_id)->
    return (feed)->
      return folder_id == feed.folder_id

  #--------------------------------------------
  # Function to filter folders without unread entries, unless the global
  # "show read feeds" flag is set.
  #--------------------------------------------
  $scope.show_folder = (folder)->
    return (folder)->
      if $rootScope.show_read
        return true
      else
        # Do not hide the currently selected folder, nor the folder of the currently selected feed
        if $rootScope.current_feed?.folder_id == folder.id || $rootScope.current_folder?.id == folder.id
          return true
        else
          return feedsFoldersSvc.folder_unread_entries(folder) > 0

  #--------------------------------------------
  # Function to convert an entry's id to an integer, for filtering purposes
  #--------------------------------------------
  $scope.entry_int_id = (entry)->
    return parseInt entry.id

]