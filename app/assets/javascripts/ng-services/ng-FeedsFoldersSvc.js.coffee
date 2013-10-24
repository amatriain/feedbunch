########################################################
# AngularJS service to load feeds and folders data in the root scope
########################################################

angular.module('feedbunch').service 'feedsFoldersSvc',
['$rootScope', '$http', 'timerFlagSvc', ($rootScope, $http, timerFlagSvc)->

  #--------------------------------------------
  # PRIVATE FUNCTION: Load feeds. Receives a boolean argument to indicate if
  # We want to load all feeds (true) or only feeds with unread entries (false).
  #--------------------------------------------
  load_feeds = (include_read)->
    $rootScope.feeds_loaded = false
    $rootScope.read_feeds_shown = include_read
    $http.get("/feeds.json?include_read=#{include_read}")
    .success (data)->
      $rootScope.feeds = data
      $rootScope.feeds_loaded = true
    .error ->
      timerFlagSvc.start 'error_loading_feeds'

  #--------------------------------------------
  # PRIVATE FUNCTION: Load folders.
  #--------------------------------------------
  load_folders = ->
    $http.get('/folders.json')
    .success (data)->
      $rootScope.folders = data
      $rootScope.folders_loaded = true
    .error ->
      timerFlagSvc.start 'error_loading_folders'

  service =

    #---------------------------------------------
    # Load feeds and folders via AJAX into the root scope
    #---------------------------------------------
    load_data: ->
      load_folders()
      load_feeds false

    #---------------------------------------------
    # Load feeds and folders via AJAX into the root scope. Receives a boolean argument to indicate if
    # We want to load all feeds (true) or only feeds with unread entries (false).
    #---------------------------------------------
    load_feeds: (include_read)->
      load_feeds include_read

    #---------------------------------------------
    # Push a feed in the feeds array. If the feeds array is empty, create it anew,
    # ensuring angularjs ng-repeat is triggered.
    #---------------------------------------------
    add_feed: (feed)->
      if $rootScope.feeds.length == 0
        $rootScope.feeds = [feed]
      else
        $rootScope.feeds.push feed

    #---------------------------------------------
    # Push a folder in the folders array. If the folders array is empty, create it anew,
    # ensuring angularjs ng-repeat is triggered.
    #---------------------------------------------
    add_folder: (folder)->
      if $rootScope.folders.length == 0
        $rootScope.folders = [folder]
      else
        $rootScope.folders.push folder

  return service
]