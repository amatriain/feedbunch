########################################################
# AngularJS service to read entries in a feed or folder
########################################################

angular.module('feedbunch').service 'readSvc',
['$rootScope', '$http', '$q', '$timeout', 'currentFeedSvc', 'currentFolderSvc', 'timerFlagSvc', 'openFolderSvc',
'entriesPaginationSvc', 'openEntrySvc', 'feedsFoldersSvc', 'favicoSvc', 'lazyLoadingSvc', 'startPageSvc',
'findSvc',
($rootScope, $http, $q, $timeout, currentFeedSvc, currentFolderSvc, timerFlagSvc, openFolderSvc,
entriesPaginationSvc, openEntrySvc, feedsFoldersSvc, favicoSvc, lazyLoadingSvc, startPageSvc,
findSvc)->

  # Maximum number of entries in each page.
  # This MUST match the entries page size set in the server!
  entries_page_size = 25

  #--------------------------------------------
  # PRIVATE FUNCTION: Validations and setup that runs every time entries are loaded.
  # Returns true if the load process can continue, false if it must be cancelled.
  #--------------------------------------------
  load_entries_setup = ->
    # If busy, do nothing
    return false if entriesPaginationSvc.is_busy()
    # If a 404 has been received in a previous page (no more entries available), do nothing
    return false if !entriesPaginationSvc.more_entries_available()

    # Cancel any running http request for entries
    $rootScope.entries_http_canceler.resolve() if $rootScope.entries_http_canceler?

    # Reset the timer that updates feeds every minute
    feedsFoldersSvc.reset_refresh_timer()
    # Increment the results page
    entriesPaginationSvc.increment_entries_page()
    # Indicate that AJAX request/response cycle is busy so no more calls are done until finished
    entriesPaginationSvc.set_busy true

    return true

  #--------------------------------------------
  # PRIVATE FUNCTION: Load entries in the feed passed as argument.
  #--------------------------------------------
  load_feed_entries = (feed)->
    return if load_entries_setup() == false

    url = "/api/feeds/#{feed.id}/entries.json"
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

      # If less than a full page of entries is received, this is the last page of entries available.
      if data.length < entries_page_size
        entriesPaginationSvc.set_more_entries_available false
        correct_feed_unread_counts feed

      if entriesPaginationSvc.is_first_page()
        # After loading the first page of entries, load a second one to ensure the list is fully populated
        load_feed_entries feed

    .error (data, status)->
      # if HTTP call has been prematurely cancelled, do nothing
      if status!=0
        $rootScope.entries_http_canceler = null
        entriesPaginationSvc.set_busy false
        if status == 404
          # there are no more entries to retrieve
          entriesPaginationSvc.set_more_entries_available false
          correct_feed_unread_counts feed

          if entriesPaginationSvc.is_first_page()
            entriesPaginationSvc.set_error_no_entries true
            feed.unread_entries = 0
        else
          currentFeedSvc.unset()
          timerFlagSvc.start 'error_loading_entries'

  #--------------------------------------------
  # PRIVATE FUNCTION: After all entries in a feed have been received, set the unread count for the feed
  # to the number of unread entries actually present.
  #--------------------------------------------
  correct_feed_unread_counts = (feed)->
    entries = findSvc.find_feed_unread_entries feed
    if entries
      feed.unread_entries = entries.length
    else
      feed.unread_entries = 0

  #--------------------------------------------
  # PRIVATE FUNCTION: Load entries in the folder passed as argument.
  #--------------------------------------------
  load_folder_entries = (folder)->
    return if load_entries_setup() == false

    url = "/api/folders/#{folder.id}/entries.json"
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

      # If less than a full page of entries is received, this is the last page of entries available.
      if data.length < entries_page_size
        entriesPaginationSvc.set_more_entries_available false
        correct_folder_unread_counts folder

      if entriesPaginationSvc.is_first_page()
        # After loading the first page of entries, load a second one to ensure the list is fully populated
        load_folder_entries folder

    .error (data, status)->
      # if HTTP call has been prematurely cancelled, do nothing
      if status!=0
        $rootScope.entries_http_canceler = null
        entriesPaginationSvc.set_busy false
        if status == 404
          # there are no more entries to retrieve
          entriesPaginationSvc.set_more_entries_available false
          correct_folder_unread_counts folder

          if entriesPaginationSvc.is_first_page()
            entriesPaginationSvc.set_error_no_entries true
            currentFeedSvc.get()?.unread_entries = 0
        else
          currentFolderSvc.unset()
          timerFlagSvc.start 'error_loading_entries'

  #--------------------------------------------
  # PRIVATE FUNCTION: After retrieving entries in a folder, set to zero the unread count of
  # feeds for which no entries have been received.
  #--------------------------------------------
  correct_folder_unread_counts = (folder)->
    feeds = findSvc.find_folder_feeds folder
    if feeds && feeds?.length > 0
      for f in feeds
        correct_feed_unread_counts f

  service =

    #---------------------------------------------
    # Load a page of entries for the currently selected feed or folder
    #---------------------------------------------
    read_entries_page: ->
      current_feed = currentFeedSvc.get()
      current_folder = currentFolderSvc.get()
      if current_feed
        load_feed_entries current_feed
      else if current_folder
        load_folder_entries current_folder

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
