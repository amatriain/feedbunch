########################################################
# AngularJS service to load feeds and folders data in the root scope
########################################################

angular.module('feedbunch').service 'feedsFoldersSvc',
['$rootScope', '$http', '$timeout', '$window', 'timerFlagSvc', 'findSvc', 'entriesPaginationSvc',
'cleanupSvc',
($rootScope, $http, $timeout, $window, timerFlagSvc, findSvc, entriesPaginationSvc,
cleanupSvc)->

  #--------------------------------------------
  # PRIVATE FUNCTION: Load feeds. Reads the boolean flag "show_read" to know if
  # we want to load all feeds (true) or only feeds with unread entries (false).
  #--------------------------------------------
  load_feeds = ->
    now = new Date()
    $http.get("/feeds.json?include_read=#{$rootScope.show_read}&time=#{now.getTime()}")
    .success (data)->
      if !$rootScope.feeds || $rootScope.feeds?.length==0
        # If there are no feeds in scope, just store the feeds returned.
        $rootScope.feeds = data
      else
        # If there are feeds already loaded in scope, replace their unread counts with the ones returned (feeds
        # not present in the returned JSON will have their unread_entries set to zero). Insert any new feeds returned.
        feeds_copy = angular.copy $rootScope.feeds

        # Set all unread counts to zero
        for feed_old in feeds_copy
          feed_old.unread_entries = 0

        # Update unread counts with those returned, and insert any new feeds (not yet in the rootScope list).
        for feed_new in data
          feed_old = findSvc.find_feed feed_new.id, feeds_copy
          if feed_old
            feed_old.unread_entries = feed_new.unread_entries
          else
            feeds_copy.push feed_new

        # Transform the working copy into the actual feeds list
        $rootScope.feeds = feeds_copy

      $rootScope.feeds_loaded = true

    .error (data, status)->
      if status == 401
        $window.location.href = '/login'
      else if status!=0
        timerFlagSvc.start 'error_loading_feeds'

  #--------------------------------------------
  # PRIVATE FUNCTION: Load feeds every minute.
  #--------------------------------------------
  refresh_feeds = ->
    $timeout ->
      load_feeds()
      refresh_feeds()
    , 60000

  #--------------------------------------------
  # PRIVATE FUNCTION: Load folders.
  #--------------------------------------------
  load_folders = ->
    now = new Date()
    $http.get("/folders.json?time=#{now.getTime()}")
    .success (data)->
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
    start_refresh_data: ->
      $rootScope.feeds_loaded = false
      $rootScope.folders_loaded = false
      $rootScope.show_read = false
      load_data()
      refresh_feeds()

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