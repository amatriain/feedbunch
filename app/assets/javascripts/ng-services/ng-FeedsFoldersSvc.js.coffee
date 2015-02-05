########################################################
# AngularJS service to load feeds and folders data in the root scope
########################################################

angular.module('feedbunch').service 'feedsFoldersSvc',
['$rootScope', '$http', '$timeout', 'timerFlagSvc', 'findSvc', 'entriesPaginationSvc',
'feedsPaginationSvc', 'cleanupSvc', 'favicoSvc', 'animationsSvc',
($rootScope, $http, $timeout, timerFlagSvc, findSvc, entriesPaginationSvc,
 feedsPaginationSvc, cleanupSvc, favicoSvc, animationsSvc)->

  # Maximum number of feeds in each page.
  # This MUST match the feeds page size set in the server!
  feeds_page_size = 25

  #--------------------------------------------
  # PRIVATE FUNCTION: Load feeds. Reads the boolean flag "show_read" to know if
  # we want to load all feeds (true) or only feeds with unread entries (false).
  #--------------------------------------------
  load_feeds = (page=0)->
    # If busy, do nothing
    return if feedsPaginationSvc.is_busy()

    # Indicate that AJAX request/response cycle is busy so no more calls are done until finished
    feedsPaginationSvc.set_busy true

    # Reset the 1-minute timer until the next feeds refresh
    $rootScope.last_data_refresh = Date.now()

    page += 1
    $http.get("/api/feeds.json?include_read=#{$rootScope.show_read}&page=#{page}")
    .success (data)->
      feedsPaginationSvc.load_feeds_page page, data.slice()
      feedsPaginationSvc.set_busy false

      # Load the next page of feeds until no more feeds are available
      if data.length < feeds_page_size
        # there are no more pages of feeds to retrieve
        $rootScope.feeds_loaded = true
        feedsPaginationSvc.pagination_finished()
        favicoSvc.update_unread_badge()
        animationsSvc.show_stats()
      else
        # There is probably at least one more page of feeds available
        load_feeds page
    .error (data, status)->
      feedsPaginationSvc.set_busy false
      if status == 404
        # if a 404 is returned for the first page, there are no feeds at all. Set all unread counts to zero.
        if page == 1
          if $rootScope.feeds && $rootScope.feeds?.length > 0
            for feed in $rootScope.feeds
              feed.unread_entries = 0
        # If a 404 is returned in a page >1, there are no more feeds and this is the last page.
        else
          feedsPaginationSvc.pagination_finished()
        $rootScope.feeds_loaded = true
        favicoSvc.update_unread_badge()
        animationsSvc.show_stats()
      else if status!=0
        timerFlagSvc.start 'error_loading_feeds'

  #--------------------------------------------
  # PRIVATE FUNCTION: Load a single feed. Receives its id as argument.
  #--------------------------------------------
  load_feed = (id)->
    # If feed pagination is busy, do nothing
    # This keeps from trying to load a single feed while the list of feeds is loading.
    return if feedsPaginationSvc.is_busy()

    # If this feed is already being loaded, do nothing
    $rootScope.loading_single_feed ||= {}
    return if $rootScope.loading_single_feed[id]

    $rootScope.loading_single_feed[id] = true
    $http.get("/api/feeds/#{id}.json")
    .success (data)->
      delete $rootScope.loading_single_feed[id]
      add_feed data
      favicoSvc.update_unread_badge()
    .error (data, status)->
      delete $rootScope.loading_single_feed[id]
      timerFlagSvc.start 'error_loading_feeds' if status!=0

  #--------------------------------------------
  # PRIVATE FUNCTION: Load feeds and folders every minute.
  #--------------------------------------------
  refresh_data = ->
    # if timestamp of last feed refresh is not yet set, set it as current time
    $rootScope.last_data_refresh = Date.now() if !$rootScope.last_data_refresh

    # Check every second if a minute has passed. Useful if timers stop running (e.g. browser is minimized in a phone)
    $timeout ->
      # load feeds every minute
      load_data() if (Date.now() - $rootScope.last_data_refresh) >= 60000
      refresh_data()
    , 1000

  #--------------------------------------------
  # PRIVATE FUNCTION: Reset the timer that loads feeds every minute.
  # If more than 90 seconds have passed since the last refresh, the timer is not reset in order to force a refresh of feeds.
  #--------------------------------------------
  reset_timer = ->
    # if timestamp of last feed refresh is not yet set, set it as current time
    if !$rootScope.last_data_refresh
      $rootScope.last_data_refresh = Date.now()
    else
      $rootScope.last_data_refresh = Date.now() if (Date.now() - $rootScope.last_data_refresh) < 90000

  #--------------------------------------------
  # PRIVATE FUNCTION: Load folders.
  #--------------------------------------------
  load_folders = ->
    $http.get("/api/folders.json")
    .success (data)->
      reset_timer()

      # Remove folders no longer existing in the server
      if $rootScope.folders? && $rootScope.folders?.length > 0
        for folder in $rootScope.folders
          existing_folder = findSvc.find_folder folder.id, data
          if !existing_folder?
            index = $rootScope.folders.indexOf folder
            $rootScope.folders.splice index, 1

      # Add new folders
      if data? && data.length? > 0
        for folder in data
          add_folder folder

      $rootScope.folders_loaded = true
    .error (data, status)->
      timerFlagSvc.start 'error_loading_folders' if status!=0

  #--------------------------------------------
  # PRIVATE FUNCTION: Load feeds inside a single folder. Receives the folder as argument.
  #--------------------------------------------
  load_folder_feeds = (folder)->
    # If feeds in this folder are already being loaded, do nothing
    $rootScope.loading_single_folder_feeds ||= {}
    return if $rootScope.loading_single_folder_feeds[folder.id]

    $rootScope.loading_single_folder_feeds[folder.id] = true

    $http.get("/api/folders/#{folder.id}/feeds.json?include_read=#{$rootScope.show_read}")
    .success (data)->
      delete $rootScope.loading_single_folder_feeds[folder.id]
      # Update unread counts with the received feeds. Set the unread counter for any feed in the folder but
      # not in the received JSON to zero.
      update_folder_feeds folder, data.slice()
    .error (data, status)->
      delete $rootScope.loading_single_folder_feeds[folder.id]
      if status==404
        # If the server returns a 404, there are no feeds to return; set unread count to zero for all feeds in
        # the folder.
        update_folder_feeds folder, null
      else if status != 0
        timerFlagSvc.start 'error_loading_folders'

  #--------------------------------------------
  # PRIVATE FUNCTION: Load feeds and folders.
  #--------------------------------------------
  load_data = ->
    load_feeds()
    load_folders()

  #---------------------------------------------
  # PRIVATE FUNCTION: Push a feed in the feeds array if it isn't already present there.
  #
  # If the feeds array has not been created in the root scope, create it.
  #
  # If the feed is already in the feeds array, its unread_entries attribute is updated instead of
  # pushing it in the array again.
  #---------------------------------------------
  add_feed = (feed)->
    if !$rootScope.feeds || $rootScope.feeds?.length == 0
      $rootScope.feeds = [feed]
    else
      feed_old = findSvc.find_feed feed.id
      if feed_old?
        feed_old.unread_entries = feed.unread_entries
      else
        $rootScope.feeds.push feed

  #---------------------------------------------
  # PRIVATE FUNCTION: Push a folder in the folders array if it isn't already present there.
  #
  # If the folders array has not been created in the root scope, create it.
  #
  # If the folder is already in the folders array, it is ignored
  #---------------------------------------------
  add_folder = (folder)->
    if !$rootScope.folders || $rootScope.folders?.length == 0
      $rootScope.folders = [folder]
    else
      old_folder = findSvc.find_folder folder.id
      $rootScope.folders.push folder if !old_folder?

  #---------------------------------------------
  # PRIVATE FUNCTION: Update the feeds and their unread counts, for feeds in a folder.
  #
  # Receives as arguments the folder and an array of feeds.
  #
  # Operations in the scope:
  # The unread_count for each feed passed in the array is updated with the value passed in the array.
  # Those feeds in the folder which are not present in the passed array will have their unread_count set to zero.
  #
  # NOTE.- If a null is passed in the feeds argument, all feeds in the folder will have their unread counts set to zero.
  #---------------------------------------------
  update_folder_feeds = (folder, feeds)->
    # Set unread count for all feeds in the folder to zero, then set the actual received value for each feed.
    # Those feeds not present in the received JSON will be set to zero.
    feeds_in_folder = findSvc.find_folder_feeds folder
    for feed in feeds_in_folder
      feed.unread_entries = 0
    if feeds? && feeds?.length > 0
      for feed in feeds
        add_feed feed

  service =

    #---------------------------------------------
    # Set to true a flag that makes all feeds (whether they have unread entries or not) and
    # all entries (whether they are read or unread) to be shown.
    #---------------------------------------------
    show_read: ->
      animationsSvc.highlight_hide_read_button()
      $rootScope.show_read = true
      entriesPaginationSvc.reset_entries()
      $rootScope.feeds_loaded = false
      feedsPaginationSvc.set_busy false
      load_feeds()

    #---------------------------------------------
    # Set to false a flag that makes only feeds with unread entries and
    # unread entries to be shown.
    #---------------------------------------------
    hide_read: ->
      animationsSvc.highlight_show_read_button()
      $rootScope.show_read = false
      entriesPaginationSvc.reset_entries()
      $rootScope.feeds_loaded = false
      cleanupSvc.hide_read_feeds()
      feedsPaginationSvc.set_busy false
      load_feeds()

    #---------------------------------------------
    # Load feeds and folders via AJAX into the root scope.
    # Start running a refresh of feeds every minute while the app is open.
    #---------------------------------------------
    start_refresh_timer: ->
      $rootScope.feeds_loaded = false
      $rootScope.folders_loaded = false
      $rootScope.show_read = false
      feedsPaginationSvc.set_busy false
      load_data()
      refresh_data()
      # When the page is retrieved from the bfcache, immediately refresh feeds
      $(window).on 'pageshow', ->
        load_feeds()

    #---------------------------------------------
    # Reset the timer that refreshes feeds every minute.
    # This means that the next refresh will happen one minute after invoking this method.
    #---------------------------------------------
    reset_refresh_timer: reset_timer

    #---------------------------------------------
    # Load feeds and folders via AJAX into the root scope.
    # Only feeds with unread entries are retrieved.
    #---------------------------------------------
    load_data: load_data

    #---------------------------------------------
    # Load feeds via AJAX into the root scope.
    #---------------------------------------------
    load_feeds: load_feeds

    #---------------------------------------------
    # Load a single feed via AJAX into the root scope.
    #---------------------------------------------
    load_feed: load_feed

    #--------------------------------------------
    # Load folders via AJAX into the root scope.
    #--------------------------------------------
    load_folders: load_folders

    #---------------------------------------------
    # Load feeds in a single folder via AJAX into the root scope.
    #---------------------------------------------
    load_folder_feeds: (folder)->
      # If passed folder is "all", load all feeds in a paginated fashion.
      if folder=="all"
        load_feeds()
      # If any other folder is passed, load feeds in that folder only (not paginated)
      else
        load_folder_feeds folder

    #---------------------------------------------
    # Push a feed in the feeds array. If the feeds array is empty, create it anew,
    # ensuring angularjs ng-repeat is triggered.
    #---------------------------------------------
    add_feed: add_feed

    #---------------------------------------------
    # Push a folder in the folders array. If the folders array is empty, create it anew,
    # ensuring angularjs ng-repeat is triggered.
    #---------------------------------------------
    add_folder: (folder)->
      if !$rootScope.folders || $rootScope.folders?.length == 0
        $rootScope.folders = [folder]
      else
        $rootScope.folders.push folder

  return service
]