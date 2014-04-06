########################################################
# AngularJS service to set, unset and recover the currently selected feed in the root scope
########################################################

angular.module('feedbunch').service 'currentFeedSvc',
['$rootScope', 'entriesPaginationSvc', 'cleanupSvc', 'findSvc', 'openFolderSvc',
($rootScope, entriesPaginationSvc, cleanupSvc, findSvc, openFolderSvc)->

  set: (feed)->
    entriesPaginationSvc.reset_entries()
    $rootScope.current_folder = null
    $rootScope.current_feed = feed
    cleanupSvc.hide_read_feeds()
    # Open the folder under which is the feed, if it isn't already open.
    if feed.folder_id != 'none'
      folder = findSvc.find_folder feed.folder_id
      openFolderSvc.set folder

  unset: ->
    entriesPaginationSvc.reset_entries()
    $rootScope.current_feed = null

  get: ->
    return findSvc.find_feed $rootScope.current_feed?.id
]