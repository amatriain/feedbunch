########################################################
# AngularJS service to read entries in a feed or folder
########################################################

angular.module('feedbunch').service 'readSvc',
['$rootScope', '$http', 'currentFeedSvc', 'currentFolderSvc', 'timerFlagSvc', 'openEntrySvc', 'openFolderSvc',
($rootScope, $http, currentFeedSvc, currentFolderSvc, timerFlagSvc, openEntrySvc, openFolderSvc)->

  #--------------------------------------------
  # PRIVATE FUNCTION: Load a feed's entries via AJAX in the root scope.
  # Receives as arguments the feed object and a boolean to indicate whether
  # to load all entries (true) or only unread ones (false).
  #--------------------------------------------
  load_feed = (feed)->
    # If busy, do nothing
    return if $rootScope.loading_entries_busy == true
    # If no feed is passed, do nothing
    return if !feed
    # If a 404 has been received in a previous page (no more entries available), do nothing
    return if !$rootScope.more_entries_available

    # Increment the results page
    $rootScope.entries_page += 1
    # During the first page load show the "loading..." message
    $rootScope.loading_entries = true if $rootScope.entries_page == 1
    # Indicate that AJAX request/response cycle is busy so no more calls are done until finished
    $rootScope.loading_entries_busy = true

    # Include read entries in the results, or only unread ones?
    include_read = if $rootScope.load_read_entries then true else false

    $http.get("/feeds/#{feed.id}.json?include_read=#{include_read}&page=#{$rootScope.entries_page}")
    .success (data)->
      $rootScope.loading_entries = false
      $rootScope.loading_entries_busy = false
      $rootScope.entries = $rootScope.entries.concat data["entries"]
      # On first page load, update unread entries count in the feed
      feed.unread_entries = data["unread_entries"] if $rootScope.page == 1
    .error (data,status)->
      $rootScope.loading_entries = false
      $rootScope.loading_entries_busy = false
      if status == 404
        $rootScope.more_entries_available = false
        timerFlagSvc.start 'error_no_entries' if $rootScope.entries_page == 1
      else
        currentFeedSvc.unset()
        timerFlagSvc.start 'error_loading_entries'

  service =

    #---------------------------------------------
    # Load a page of entries for the currently selected feed or folder
    #---------------------------------------------
    read_entries_page: (current_feed, current_folder)->
      if current_feed
        load_feed current_feed
      else if current_folder
        load_folder current_folder

    #---------------------------------------------
    # Load a feed's unread entries in the root scope
    #---------------------------------------------
    read_feed: (feed)->
      currentFeedSvc.set feed
      load_feed feed, false

    #---------------------------------------------
    # Load all of the current feed's entries, both read and unread
    #---------------------------------------------
    read_feed_all: ->
      openEntrySvc.unset()
      load_feed currentFeedSvc.get(), true

    #--------------------------------------------
    # Load a folder's unread entries
    #--------------------------------------------
    read_folder: (folder)->
      currentFolderSvc.set folder
      $rootScope.loading_entries = true

      $http.get("/folders/#{folder.id}.json")
      .success (data)->
        $rootScope.loading_entries = false
        $rootScope.entries = data["entries"]
      .error (data,status)->
        $rootScope.loading_entries = false
        if status == 404
          timerFlagSvc.start 'error_no_entries'
        else
          timerFlagSvc.start 'error_loading_entries'

    #--------------------------------------------
    # Refresh a feed and load its unread entries
    #--------------------------------------------
    refresh_feed: ->
      openEntrySvc.unset()
      $rootScope.loading_entries = true

      $http.put("/feeds/#{currentFeedSvc.get().id}.json")
      .success (data)->
        load_feed currentFeedSvc.get(), false
      .error ->
        $rootScope.loading_entries = false
        timerFlagSvc.start 'error_refreshing_feed'

    #--------------------------------------------
    # Mark a single folder as open in the scope
    #--------------------------------------------
    open_folder: (folder)->
      if openFolderSvc.get() == folder
        # User is closing the open folder
        openFolderSvc.unset()
      else
        openFolderSvc.set folder

  return service
]
