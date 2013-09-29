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
  load_feed = (feed, include_read_entries)->
    return if $rootScope.loading_entries_busy == true || !feed
    #$rootScope.loading_entries = true
    $rootScope.entries_page += 1
    $rootScope.loading_entries_busy = true

    $http.get("/feeds/#{feed.id}.json?include_read=#{include_read_entries}&page=#{$rootScope.entries_page}")
    .success (data)->
      $rootScope.loading_entries = false
      $rootScope.loading_entries_busy = false
      $rootScope.entries = $rootScope.entries.concat data["entries"]
      feed.unread_entries = data["unread_entries"]
    .error (data,status)->
      $rootScope.loading_entries = false
      $rootScope.loading_entries_busy = false
      if status == 404
        timerFlagSvc.start 'error_no_entries' if $rootScope.entries_page == 1
      else
        currentFeedSvc.unset()
        timerFlagSvc.start 'error_loading_entries'

  service =
    #---------------------------------------------
    # Load a feed's unread entries in the root scope
    #---------------------------------------------
    read_feed: (feed)->
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