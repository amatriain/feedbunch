########################################################
# AngularJS service to read entries in a feed or folder
########################################################

angular.module('feedbunch').service 'readSvc',
['$rootScope', '$http', 'currentFeedSvc', 'currentFolderSvc', 'timerFlagSvc', 'openEntrySvc', 'openFolderSvc',
 'entriesPaginationSvc',
($rootScope, $http, currentFeedSvc, currentFolderSvc, timerFlagSvc, openEntrySvc, openFolderSvc,
 entriesPaginationSvc)->

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
      # On first page load, update unread entries count in the feed
      currentFeedSvc.get().unread_entries = data["unread_entries"] if currentFeedSvc.get() && entriesPaginationSvc.is_first_page()
    .error (data,status)->
      entriesPaginationSvc.set_busy false
      if status == 404
        entriesPaginationSvc.set_more_entries_available false
        if entriesPaginationSvc.is_first_page()
          entriesPaginationSvc.set_error_no_entries true
          currentFeedSvc.get().unread_entries = 0
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
      entriesPaginationSvc.reset_entries()
      entriesPaginationSvc.set_busy true

      $http.put("/feeds/#{currentFeedSvc.get().id}.json")
      .success (data)->
        entriesPaginationSvc.set_busy false
        load_entries()
      .error ->
        entriesPaginationSvc.set_busy false
        timerFlagSvc.start 'error_refreshing_feed'

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
