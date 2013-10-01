########################################################
# AngularJS service to read entries in a feed or folder
########################################################

angular.module('feedbunch').service 'readSvc',
['$rootScope', '$http', 'currentFeedSvc', 'currentFolderSvc', 'timerFlagSvc', 'openEntrySvc', 'openFolderSvc', 'entriesPaginationSvc',
($rootScope, $http, currentFeedSvc, currentFolderSvc, timerFlagSvc, openEntrySvc, openFolderSvc, entriesPaginationSvc)->

  #--------------------------------------------
  # PRIVATE FUNCTION: Load entries via AJAX in the root scope.
  #--------------------------------------------
  load_entries = ->
    # If busy, do nothing
    return if entriesPaginationSvc.is_busy()
    # If no feed or folder is selected, do nothing
    return if !currentFeedSvc.get() && !currentFolderSvc.get()
    # If a 404 has been received in a previous page (no more entries available), do nothing
    return if !entriesPaginationSvc.more_entries_available()

    # Increment the results page
    entriesPaginationSvc.increment_entries_page()
    # During the first page load show the "loading..." message
    $rootScope.loading_entries = true if entriesPaginationSvc.is_first_page()
    # Indicate that AJAX request/response cycle is busy so no more calls are done until finished
    entriesPaginationSvc.set_busy true

    # Load entries from a feed or from a folder?
    if currentFeedSvc.get()
      # Include read entries in the results, or only unread ones?
      include_read = if $rootScope.load_read_entries then true else false
      url = "/feeds/#{currentFeedSvc.get().id}.json?include_read=#{include_read}&page=#{entriesPaginationSvc.get_entries_page()}"
    else if currentFolderSvc.get()
      url = "/folders/#{currentFolderSvc.get().id}.json?page=#{entriesPaginationSvc.get_entries_page()}"

    $http.get(url)
    .success (data)->
      entriesPaginationSvc.set_busy false
      $rootScope.entries = $rootScope.entries.concat data["entries"]
      if entriesPaginationSvc.is_first_page()
        # "Loading..." message is only shown while loading the first page of results
        $rootScope.loading_entries = false
        # On first page load, update unread entries count in the feed
        currentFeedSvc.get().unread_entries = data["unread_entries"] if currentFeedSvc.get()
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
      load_entries()

    #---------------------------------------------
    # Load all of the current feed's entries, both read and unread
    #---------------------------------------------
    read_feed_all: ->
      entriesPaginationSvc.reset_entries()
      $rootScope.load_read_entries = true
      load_entries()

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
