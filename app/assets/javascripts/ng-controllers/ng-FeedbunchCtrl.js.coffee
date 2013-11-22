########################################################
# AngularJS controller file
########################################################

angular.module('feedbunch').controller 'FeedbunchCtrl',
['$rootScope', '$scope', 'feedsFoldersSvc', 'importStatusSvc', 'timerFlagSvc',
'currentFeedSvc', 'currentFolderSvc', 'subscriptionSvc', 'readSvc', 'folderSvc', 'entrySvc', 'entriesPaginationSvc',
'findSvc', 'userDataSvc',
($rootScope, $scope, feedsFoldersSvc, importStatusSvc, timerFlagSvc,
currentFeedSvc, currentFolderSvc, subscriptionSvc, readSvc, folderSvc, entrySvc, entriesPaginationSvc,
findSvc, userDataSvc)->

  # Show Add Subscription button in this view
  $rootScope.show_feed_buttons = true

  # Load configuration data for the current user
  userDataSvc.load_data()

  # Load folders and feeds via AJAX on startup
  feedsFoldersSvc.start_refresh_data()

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
  # Show all feeds (regardless of whether they have unread entries or not)
  # and all entries (regardless of whether they are read or not).
  #--------------------------------------------
  $scope.show_read_feeds_entries = ->
    feedsFoldersSvc.show_read()
    readSvc.read_entries_page()

  #--------------------------------------------
  # Show only feeds with unread entries and unread entries.
  #--------------------------------------------
  $scope.hide_read_feeds_entries = ->
    feedsFoldersSvc.hide_read()
    readSvc.read_entries_page()

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
  # Get the currently selected feed
  #--------------------------------------------
  $scope.get_current_feed = ->
    return currentFeedSvc.get()

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
  $scope.read_entries_page = ->
    readSvc.read_entries_page()

  #--------------------------------------------
  # Refresh a feed and load its unread entries
  #--------------------------------------------
  $scope.refresh_feed = ->
    readSvc.refresh_feed()

  #--------------------------------------------
  # Mark a single folder as open in the scope
  #--------------------------------------------
  $scope.toggle_open_folder = (folder)->
    readSvc.toggle_open_folder folder

  #--------------------------------------------
  # Toggle open/close for an entry. Mark it as read if opening.
  #--------------------------------------------
  $scope.toggle_open_entry = (entry)->
    entrySvc.toggle_open_entry entry

  #--------------------------------------------
  # Mark all entries as read
  #--------------------------------------------
  $scope.mark_all_read = ->
    entrySvc.mark_all_read()

  #--------------------------------------------
  # Mark a single entry as unread
  #--------------------------------------------
  $scope.unread_entry = (entry)->
    entrySvc.unread_entry(entry)

  #--------------------------------------------
  # Mark a single entry as read
  #--------------------------------------------
  $scope.read_entry = (entry)->
    entrySvc.read_entry(entry)

  #--------------------------------------------
  # Return the title of the feed to which an entry belongs
  #--------------------------------------------
  $scope.entry_feed_title = (entry)->
    entrySvc.entry_feed_title entry

  #--------------------------------------------
  # Set the feed to which belongs the passed entry as the currently selected feed
  #--------------------------------------------
  $scope.set_current_entry_feed = (entry)->
    feed = findSvc.find_feed entry.feed_id
    if feed
      currentFeedSvc.set feed
      readSvc.read_entries_page()

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
        current_feed = currentFeedSvc.get()
        current_folder = currentFolderSvc.get()
        if current_feed?.folder_id == folder.id || current_folder?.id == folder.id
          return true
        else
          return feedsFoldersSvc.folder_unread_entries(folder) > 0

  #--------------------------------------------
  # Function to decide if an entry should be displayed as open (return true) or closed (return false).
  #--------------------------------------------
  $scope.entry_opened = (entry)->
    return $rootScope.open_entry?.id==entry.id

  #--------------------------------------------
  # Function to convert an entry's id to an integer, for filtering purposes
  #--------------------------------------------
  $scope.entry_int_id = (entry)->
    return parseInt entry.id

]