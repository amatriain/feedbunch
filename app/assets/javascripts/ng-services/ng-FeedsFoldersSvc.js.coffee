########################################################
# AngularJS service to load feeds and folders data in the root scope
########################################################

angular.module('feedbunch').service 'feedsFoldersSvc',
['$rootScope', '$http', 'timerFlagSvc', ($rootScope, $http, timerFlagSvc)->

  #---------------------------------------------
  # Load feeds and folders via AJAX into the root scope
  #---------------------------------------------
  load_data: ->
    $http.get('/folders.json')
    .success (data)->
      $rootScope.folders = data
    .error ->
      timerFlagSvc.start 'error_loading_folders'

    $http.get('/feeds.json')
    .success (data)->
      $rootScope.feeds = data
    .error ->
      timerFlagSvc.start 'error_loading_feeds'

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
]