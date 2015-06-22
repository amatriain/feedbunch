########################################################
# AngularJS service to set and recover the currently selected feed in the root scope
########################################################

angular.module('feedbunch').service 'currentFeedSvc',
['$rootScope', 'entriesPaginationSvc', 'cleanupSvc', 'findSvc', 'openFolderSvc', 'tooltipSvc', 'feedsFoldersSvc',
'readSvc', 'menuCollapseSvc', 'sidebarVisibleSvc', 'tourSvc',
($rootScope, entriesPaginationSvc, cleanupSvc, findSvc, openFolderSvc, tooltipSvc, feedsFoldersSvc,
readSvc, menuCollapseSvc, sidebarVisibleSvc, tourSvc)->

  set: (feed)->
    if feed?
      entriesPaginationSvc.reset_entries()
      $rootScope.current_folder = null
      $rootScope.current_feed = feed
      cleanupSvc.hide_read_feeds()
      # Open the folder under which is the feed, if it isn't already open.
      if feed.folder_id != 'none'
        folder = findSvc.find_folder feed.folder_id
        openFolderSvc.set folder
      tooltipSvc.feed_title_tooltip()
      feedsFoldersSvc.load_feed feed.id
      readSvc.read_entries_page()
      menuCollapseSvc.close()
      sidebarVisibleSvc.set false
      tourSvc.show_feed_tour()

  get: ->
    return findSvc.find_feed $rootScope.current_feed?.id
]