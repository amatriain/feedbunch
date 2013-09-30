########################################################
# AngularJS service to set, unset and recover the currently selected feed in the root scope
########################################################

angular.module('feedbunch').service 'currentFeedSvc',
['$rootScope', 'entriesPaginationSvc', ($rootScope, entriesPaginationSvc)->

  set: (feed)->
    entriesPaginationSvc.reset_entries()
    $rootScope.current_folder = null
    $rootScope.current_feed = feed

  unset: ->
    entriesPaginationSvc.reset_entries()
    $rootScope.current_feed = null

  get: ->
    $rootScope.current_feed
]