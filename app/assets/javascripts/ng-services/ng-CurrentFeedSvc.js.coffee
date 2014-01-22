########################################################
# AngularJS service to set, unset and recover the currently selected feed in the root scope
########################################################

angular.module('feedbunch').service 'currentFeedSvc',
['$rootScope', 'entriesPaginationSvc', 'cleanupSvc', 'findSvc',
($rootScope, entriesPaginationSvc, cleanupSvc, findSvc)->

  set: (feed)->
    entriesPaginationSvc.reset_entries()
    $rootScope.current_folder = null
    $rootScope.current_feed = feed
    cleanupSvc.hide_read_feeds()

  unset: ->
    entriesPaginationSvc.reset_entries()
    $rootScope.current_feed = null

  get: ->
    return findSvc.find_feed $rootScope.current_feed?.id
]