########################################################
# AngularJS service to load feeds and folders data in the root scope
########################################################

angular.module('feedbunch').service 'feedsFoldersSvc',
['$rootScope', '$http', '$timeout', '$window', 'timerFlagSvc', 'findSvc', 'entriesPaginationSvc',
'feedsPaginationSvc', 'cleanupSvc',
($rootScope, $http, $timeout, $window, timerFlagSvc, findSvc, entriesPaginationSvc,
 feedsPaginationSvc, cleanupSvc)->

  #--------------------------------------------
  # PRIVATE FUNCTION: Load feeds. Reads the boolean flag "show_read" to know if
  # we want to load all feeds (true) or only feeds with unread entries (false).
  #--------------------------------------------
  load_feeds = (page=0)->
    page += 1
    now = new Date()
    $http.get("/feeds.json?include_read=#{$rootScope.show_read}&page=#{page}&time=#{now.getTime()}")
    .success (data)->
      feedsPaginationSvc.load_feeds_page page, data
      # Load the next page of feeds, until a 404 (no more feeds) is received
      load_feeds page
    .error (data, status)->
      if status == 404
        # there are no more feeds to retrieve
        $rootScope.feeds_loaded = true
        feedsPaginationSvc.pagination_finished()
      else if status == 401
        $window.location.href = '/login'
      else if status!=0
        timerFlagSvc.start 'error_loading_feeds'

  #--------------------------------------------
  # PRIVATE FUNCTION: Load feeds every minute.
  #--------------------------------------------
  refresh_feeds = ->
    $rootScope.refresh_timer = $timeout ->
      load_feeds()
      refresh_feeds()
    , 60000

  #--------------------------------------------
  # PRIVATE FUNCTION: Reset the timer that loads feeds every minute.
  #--------------------------------------------
  reset_timer = ->
    if $rootScope.refresh_timer?
      $timeout.cancel $rootScope.refresh_timer
    refresh_feeds()

  #--------------------------------------------
  # PRIVATE FUNCTION: Load folders.
  #--------------------------------------------
  load_folders = ->
    now = new Date()
    $http.get("/folders.json?time=#{now.getTime()}")
    .success (data)->
      reset_timer()
      $rootScope.folders = data
      $rootScope.folders_loaded = true
    .error (data, status)->
      if status == 401
        $window.location.href = '/login'
      else if status!=0
        timerFlagSvc.start 'error_loading_folders'

  #--------------------------------------------
  # PRIVATE FUNCTION: Load feeds and folders.
  #--------------------------------------------
  load_data = ->
    load_folders()
    load_feeds()

  service =

    #---------------------------------------------
    # Set to true a flag that makes all feeds (whether they have unread entries or not) and
    # all entries (whether they are read or unread) to be shown.
    #---------------------------------------------
    show_read: ->
      $rootScope.show_read = true
      entriesPaginationSvc.reset_entries()
      $rootScope.feeds_loaded = false
      load_feeds()

    #---------------------------------------------
    # Set to false a flag that makes only feeds with unread entries and
    # unread entries to be shown.
    #---------------------------------------------
    hide_read: ->
      $rootScope.show_read = false
      entriesPaginationSvc.reset_entries()
      $rootScope.feeds_loaded = false
      cleanupSvc.hide_read_feeds()
      load_feeds()

    #---------------------------------------------
    # Load feeds and folders via AJAX into the root scope.
    # Start running a refresh of feeds every minute while the app is open.
    #---------------------------------------------
    start_refresh_timer: ->
      $rootScope.feeds_loaded = false
      $rootScope.folders_loaded = false
      $rootScope.show_read = false
      load_data()
      refresh_feeds()

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

    #--------------------------------------------
    # Load folders via AJAX into the root scope.
    #--------------------------------------------
    load_folders: load_folders

    #---------------------------------------------
    # Push a feed in the feeds array. If the feeds array is empty, create it anew,
    # ensuring angularjs ng-repeat is triggered.
    #---------------------------------------------
    add_feed: (feed)->
      if !$rootScope.feeds || $rootScope.feeds?.length == 0
        $rootScope.feeds = [feed]
      else
        $rootScope.feeds.push feed

    #---------------------------------------------
    # Push a folder in the folders array. If the folders array is empty, create it anew,
    # ensuring angularjs ng-repeat is triggered.
    #---------------------------------------------
    add_folder: (folder)->
      if !$rootScope.folders || $rootScope.folders?.length == 0
        $rootScope.folders = [folder]
      else
        $rootScope.folders.push folder

    #--------------------------------------------
    # Count the number of unread entries in a folder
    #--------------------------------------------
    folder_unread_entries: (folder)->
      sum = 0
      feeds = findSvc.find_folder_feeds folder
      if feeds && feeds?.length > 0
        for feed in feeds
          sum += feed.unread_entries
      return sum

    #--------------------------------------------
    # Count the total number of unread entries in feeds
    #--------------------------------------------
    total_unread_entries: ->
      sum = 0
      if $rootScope.feeds && $rootScope.feeds?.length > 0
        for feed in $rootScope.feeds
          sum += feed.unread_entries
      return sum

  return service
]