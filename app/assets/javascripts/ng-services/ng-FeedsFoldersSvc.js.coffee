########################################################
# AngularJS service to load feeds and folders data in the root scope
########################################################

angular.module('feedbunch').service 'feedsFoldersSvc',
['$rootScope', '$timeout', 'feedsPaginationSvc', 'loadFeedsSvc', 'loadFoldersSvc',
($rootScope, $timeout, feedsPaginationSvc, loadFeedsSvc, loadFoldersSvc)->

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
  # PRIVATE FUNCTION: Load feeds and folders.
  #--------------------------------------------
  load_data = ->
    # Reset the 1-minute timer until the next data refresh
    $rootScope.last_data_refresh = Date.now()
    loadFeedsSvc.load_feeds()
    loadFoldersSvc.load_folders()

  service =

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
        loadFeedsSvc.load_feeds()

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

  return service
]