########################################################
# AngularJS service to read entries in a feed or folder
########################################################

angular.module('feedbunch').service 'readSvc',
['$rootScope', '$http', '$q', '$timeout', 'currentFeedSvc', 'currentFolderSvc', 'timerFlagSvc', 'openFolderSvc',
 'entriesPaginationSvc', 'openEntrySvc', 'feedsFoldersSvc', 'favicoSvc', 'lazyLoadingSvc', 'startPageSvc',
($rootScope, $http, $q, $timeout, currentFeedSvc, currentFolderSvc, timerFlagSvc, openFolderSvc,
 entriesPaginationSvc, openEntrySvc, feedsFoldersSvc, favicoSvc, lazyLoadingSvc, startPageSvc)->

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

    # Cancel any running http request for entries
    $rootScope.entries_http_canceler.resolve() if $rootScope.entries_http_canceler?

    # Reset the timer that updates feeds every minute
    feedsFoldersSvc.reset_refresh_timer()
    # Increment the results page
    entriesPaginationSvc.increment_entries_page()
    # Indicate that AJAX request/response cycle is busy so no more calls are done until finished
    entriesPaginationSvc.set_busy true

    # Load entries from a feed or from a folder?
    if currentFeedSvc.get()
      url = "/api/feeds/#{currentFeedSvc.get().id}/entries.json"
    else if currentFolderSvc.get()
      url = "/api/folders/#{currentFolderSvc.get().id}/entries.json"

    now = new Date()
    $rootScope.entries_http_canceler = $q.defer()
    $http.get("#{url}?include_read=#{$rootScope.show_read}&page=#{entriesPaginationSvc.get_entries_page()}&time=#{now.getTime()}",
      {timeout: $rootScope.entries_http_canceler.promise})
    .success (data)->
      $rootScope.entries_http_canceler = null
      entriesPaginationSvc.set_busy false

      if !$rootScope.entries || $rootScope.entries?.length == 0
        $rootScope.entries = data.slice()
      else
        $rootScope.entries = $rootScope.entries.concat data.slice()

      # Set correct state (open or closed) for new entries, based on user configuration
      openEntrySvc.add_entries data.slice()

      # If the user has selected the "open all entries by default" option, lazy load images
      if $rootScope.open_all_entries
        $timeout ->
          lazyLoadingSvc.load_viewport_images()
        , 250

      if entriesPaginationSvc.is_first_page()
        current_feed = currentFeedSvc.get()
        # On first page load, update unread entries count in the feed
        #if current_feed
          #TODO retrieve a single feed's JSON when clicking on entry
          #current_feed.unread_entries = data["unread_entries"]
          #favicoSvc.update_unread_badge()
        # After loading the first page of entries, load a second one to ensure the list is fully populated
        load_entries()

    .error (data, status)->
      # if HTTP call has been prematurely cancelled, do nothing
      if status!=0
        $rootScope.entries_http_canceler = null
        entriesPaginationSvc.set_busy false
        if status == 404
          # there are no more entries to retrieve
          entriesPaginationSvc.set_more_entries_available false
          if entriesPaginationSvc.is_first_page()
            entriesPaginationSvc.set_error_no_entries true
            currentFeedSvc.get()?.unread_entries = 0
        else
          currentFeedSvc.unset()
          timerFlagSvc.start 'error_loading_entries'

  service =

    #---------------------------------------------
    # Load a page of entries for the currently selected feed or folder
    #---------------------------------------------
    read_entries_page: ->
      load_entries()

    #--------------------------------------------
    # Refresh a feed and load its unread entries
    #--------------------------------------------
    refresh_feed: ->
      entriesPaginationSvc.reset_entries()
      entriesPaginationSvc.set_busy true

      $http.put("/api/feeds/#{currentFeedSvc.get().id}.json")
      .success (data)->
        startPageSvc.show_start_page()
      .error (data, status)->
        entriesPaginationSvc.set_busy false
        timerFlagSvc.start 'error_refreshing_feed' if status!=0

    #--------------------------------------------
    # Toggle open folder in the root scope.
    #--------------------------------------------
    toggle_open_folder: (folder)->
      if openFolderSvc.get()?.id == folder.id
        # User is closing the open folder
        openFolderSvc.unset()
      else
        openFolderSvc.set folder

  return service
]
