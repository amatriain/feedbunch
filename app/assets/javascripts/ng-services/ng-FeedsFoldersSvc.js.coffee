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
]