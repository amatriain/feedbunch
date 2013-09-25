########################################################
# AngularJS service to set, unset and recover the currently selected feed in the root scope
########################################################

angular.module('feedbunch').service 'currentFeedSvc',
['$rootScope', ($rootScope)->

  set: (feed)->
    $rootScope.current_folder = null
    $rootScope.open_entry = null
    $rootScope.current_feed = feed

  unset: ->
    $rootScope.open_entry = null
    $rootScope.current_feed = null

  get: ->
    $rootScope.current_feed
]