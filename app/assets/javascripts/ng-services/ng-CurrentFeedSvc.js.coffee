########################################################
# AngularJS service to set, unset and recover the currently selected feed in the root scope
########################################################

angular.module('feedbunch').service 'currentFeedSvc',
['$rootScope', 'entriesPaginationSvc', 'cleanupSvc', 'findSvc', 'sidebarVisibleSvc', 'menuCollapseSvc',
($rootScope, entriesPaginationSvc, cleanupSvc, findSvc, sidebarVisibleSvc, menuCollapseSvc)->

  set: (feed)->
    entriesPaginationSvc.reset_entries()
    $rootScope.current_folder = null
    $rootScope.current_feed = feed
    cleanupSvc.hide_read_feeds()
    sidebarVisibleSvc.toggle()
    menuCollapseSvc.close()

  unset: ->
    entriesPaginationSvc.reset_entries()
    $rootScope.current_feed = null

  get: ->
    return findSvc.find_feed $rootScope.current_feed?.id
]