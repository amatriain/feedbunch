########################################################
# AngularJS controller file
########################################################

angular.module('feedbunch').controller 'FeedbunchCtrl',
['$rootScope', '$scope', '$timeout', '$sce', 'feedsFoldersSvc', 'importStatusSvc', 'timerFlagSvc',
'currentFeedSvc', 'currentFolderSvc', 'subscriptionSvc', 'readSvc', 'folderSvc', 'entrySvc', 'entriesPaginationSvc',
'findSvc', 'userDataSvc', 'openEntrySvc', 'unreadCountSvc', 'sidebarVisibleSvc', 'menuCollapseSvc',
($rootScope, $scope, $timeout, $sce, feedsFoldersSvc, importStatusSvc, timerFlagSvc,
currentFeedSvc, currentFolderSvc, subscriptionSvc, readSvc, folderSvc, entrySvc, entriesPaginationSvc,
findSvc, userDataSvc, openEntrySvc, unreadCountSvc, sidebarVisibleSvc, menuCollapseSvc)->

  #--------------------------------------------
  # APPLICATION INITIALIZATION
  #--------------------------------------------

  # By default sidebar is visible in smartphones and other small screens
  sidebarVisibleSvc.set true

  # Show Add Subscription button in this view
  $rootScope.show_feed_buttons = true

  # Load configuration data for the current user
  userDataSvc.load_data()

  # Load folders and feeds via AJAX on startup
  feedsFoldersSvc.start_refresh_timer()

  # Load status of data import process for the current user
  importStatusSvc.load_data false

  # If there is a rails alert, show it and close it after 5 seconds
  timerFlagSvc.start 'error_rails'

  # Initialize collapsing menu in smartphones
  menuCollapseSvc.start()

  #--------------------------------------------
  # Show the start page
  #--------------------------------------------
  $scope.show_start_page = ->
    currentFeedSvc.unset()
    currentFolderSvc.unset()
    entriesPaginationSvc.set_busy false
    menuCollapseSvc.close()
    $timeout ->
      sidebarVisibleSvc.toggle()
    , 300

  #--------------------------------------------
  # Unsubscribe from a feed
  #--------------------------------------------
  $scope.unsubscribe = ->
    subscriptionSvc.unsubscribe()
    menuCollapseSvc.close()

  #--------------------------------------------
  # Subscribe to a feed
  #--------------------------------------------
  $scope.subscribe = ->
    $("#subscribe-feed-popup").modal 'hide'
    subscriptionSvc.subscribe $scope.subscription_url
    $scope.subscription_url = null
    menuCollapseSvc.close()

  #--------------------------------------------
  # Show all feeds (regardless of whether they have unread entries or not)
  # and all entries (regardless of whether they are read or not).
  #--------------------------------------------
  $scope.show_read_feeds_entries = ->
    feedsFoldersSvc.show_read()
    readSvc.read_entries_page()
    menuCollapseSvc.close()

  #--------------------------------------------
  # Show only feeds with unread entries and unread entries.
  #--------------------------------------------
  $scope.hide_read_feeds_entries = ->
    feedsFoldersSvc.hide_read()
    readSvc.read_entries_page()
    menuCollapseSvc.close()

  #--------------------------------------------
  # Remove a feed from a folder
  #--------------------------------------------
  $scope.remove_from_folder = ->
    folderSvc.remove_from_folder()
    menuCollapseSvc.close()

  #--------------------------------------------
  # Move a feed to an already existing folder
  #--------------------------------------------
  $scope.move_to_folder = (folder)->
    folderSvc.move_to_folder folder
    menuCollapseSvc.close()

  #--------------------------------------------
  # Move a feed to a new folder
  #--------------------------------------------
  $scope.move_to_new_folder = ()->
    $("#new-folder-popup").modal 'hide'
    folderSvc.move_to_new_folder $scope.new_folder_title
    $scope.new_folder_title = null
    menuCollapseSvc.close()

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
    menuCollapseSvc.close()
    $timeout ->
      sidebarVisibleSvc.toggle()
    , 300

  #--------------------------------------------
  # Set the currently selected folder
  #--------------------------------------------
  $scope.set_current_folder = (folder)->
    currentFolderSvc.set folder
    readSvc.read_entries_page()
    menuCollapseSvc.close()
    $timeout ->
      sidebarVisibleSvc.toggle()
    , 300

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
    menuCollapseSvc.close()

  #--------------------------------------------
  # Mark a single folder as open in the scope
  #--------------------------------------------
  $scope.toggle_open_folder = (folder)->
    readSvc.toggle_open_folder folder
    menuCollapseSvc.close()

  #--------------------------------------------
  # Toggle open/close for an entry. Mark it as read if opening.
  #--------------------------------------------
  $scope.toggle_open_entry = (entry)->
    entrySvc.toggle_open_entry entry
    menuCollapseSvc.close()

  #--------------------------------------------
  # Function to decide if an entry should be displayed as open (return true) or closed (return false).
  #--------------------------------------------
  $scope.is_open = (entry)->
    openEntrySvc.is_open entry

  #--------------------------------------------
  # Mark all entries as read
  #--------------------------------------------
  $scope.mark_all_read = ->
    entrySvc.mark_all_read()
    menuCollapseSvc.close()

  #--------------------------------------------
  # Mark a single entry as unread
  #--------------------------------------------
  $scope.unread_entry = (entry)->
    entrySvc.unread_entry entry
    menuCollapseSvc.close()

  #--------------------------------------------
  # Mark a single entry as read
  #--------------------------------------------
  $scope.read_entry = (entry)->
    entrySvc.read_entry entry
    menuCollapseSvc.close()

  #--------------------------------------------
  # Return the title of the feed to which an entry belongs
  #--------------------------------------------
  $scope.entry_feed_title = (entry)->
    entrySvc.entry_feed_title entry

  #--------------------------------------------
  # Set the feed to which belongs the passed entry as the currently selected feed.
  # Also the passed entry is marked as unread, so that it's visible in the new list of entries.
  #--------------------------------------------
  $scope.set_current_entry_feed = (entry)->
    entrySvc.load_entry_feed entry
    menuCollapseSvc.close()

  #--------------------------------------------
  # Return the HTML content or summary of an entry, explicitly marked as trusted HTML for binding.
  #--------------------------------------------
  $scope.trustedEntryContent = (entry)->
    html = ''
    # Return the content if present; otherwise try to return the summary.
    if entry.content?.length > 0
      html = entry.content
    else if entry.summary?.length > 0
      html = entry.summary
    return $sce.trustAsHtml html


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
    unreadCountSvc.folder_unread_entries folder

  #--------------------------------------------
  # Count the total number of unread entries in feeds
  #--------------------------------------------
  $scope.total_unread_entries = ->
    unreadCountSvc.total_unread_entries()

  #--------------------------------------------
  # Toggle a boolean in the root scope that indicates if the sidebar with feeds/folders is
  # visible (true) or the entries list is visible (false).
  #--------------------------------------------
  $scope.toggle_sidebar_visible = ->
    sidebarVisibleSvc.toggle()
    menuCollapseSvc.close()

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
          return unreadCountSvc.folder_unread_entries(folder) > 0

  #--------------------------------------------
  # Return a boolean indicating whether the "all subscriptions" link in a folder
  # should be show (if true) or not (if false).
  # The "all subscriptions" link is shown only when there is more than one visible feed in the folder.
  #--------------------------------------------
  $scope.show_all_subscriptions = (folder)->
    feeds = findSvc.find_folder_feeds folder
    return feeds?.length > 1

  #--------------------------------------------
  # Function to convert an entry's id to an integer, for filtering purposes
  #--------------------------------------------
  $scope.entry_int_id = (entry)->
    return parseInt entry.id

]