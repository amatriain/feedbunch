########################################################
# AngularJS service to read entries in a feed or folder
########################################################

angular.module('feedbunch').service 'readSvc',
['$rootScope', '$http', 'currentFeedSvc', 'currentFolderSvc', 'timerFlagSvc', 'openEntrySvc', 'openFolderSvc', 'entriesPaginationSvc',
($rootScope, $http, currentFeedSvc, currentFolderSvc, timerFlagSvc, openEntrySvc, openFolderSvc, entriesPaginationSvc)->

  #--------------------------------------------
  # PRIVATE FUNCTION: Load a feed's entries via AJAX in the root scope.
  # Receives as arguments the feed object and a boolean to indicate whether
  # to load all entries (true) or only unread ones (false).
  #--------------------------------------------
  load_feed = (feed)->
    # If busy, do nothing
    return if entriesPaginationSvc.is_busy()
    # If no feed is passed, do nothing
    return if !feed
    # If a 404 has been received in a previous page (no more entries available), do nothing
    return if !entriesPaginationSvc.more_entries_available()

    # Increment the results page
    entriesPaginationSvc.increment_entries_page()
    # During the first page load show the "loading..." message
    $rootScope.loading_entries = true if entriesPaginationSvc.is_first_page()
    # Indicate that AJAX request/response cycle is busy so no more calls are done until finished
    entriesPaginationSvc.set_busy true

    # Include read entries in the results, or only unread ones?
    include_read = if $rootScope.load_read_entries then true else false

    $http.get("/feeds/#{feed.id}.json?include_read=#{include_read}&page=#{$rootScope.entries_page}")
    .success (data)->
      entriesPaginationSvc.set_busy false
      $rootScope.entries = $rootScope.entries.concat data["entries"]
      if entriesPaginationSvc.is_first_page()
        # "Loading..." message is only shown while loading the first page of results
        $rootScope.loading_entries = false
        # On first page load, update unread entries count in the feed
        feed.unread_entries = data["unread_entries"]
    .error (data,status)->
      $rootScope.loading_entries = false
      entriesPaginationSvc.set_busy false
      if status == 404
        entriesPaginationSvc.set_more_entries_available false
        timerFlagSvc.start 'error_no_entries' if entriesPaginationSvc.is_first_page()
      else
        currentFeedSvc.unset()
        timerFlagSvc.start 'error_loading_entries'

  service =

    #---------------------------------------------
    # Load a page of entries for the currently selected feed or folder
    #---------------------------------------------
    read_entries_page: ->
      if currentFeedSvc.get()
        load_feed currentFeedSvc.get()
      else if currentFolderSvc.get()
        load_folder currentFolderSvc.get()

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
