########################################################
# AngularJS service to load user configuration in the scope.
########################################################

angular.module('feedbunch').service 'showHideReadSvc',
['$rootScope', 'animationsSvc', 'entriesPaginationSvc', 'feedsPaginationSvc', 'highlightedSidebarLinkSvc',
'feedsFoldersTimerSvc', 'cleanupSvc',
($rootScope, animationsSvc, entriesPaginationSvc, feedsPaginationSvc, highlightedSidebarLinkSvc,
feedsFoldersTimerSvc, cleanupSvc)->

  service =

    #---------------------------------------------
    # Set to true a flag that makes all feeds (whether they have unread entries or not) and
    # all entries (whether they are read or unread) to be shown.
    #---------------------------------------------
    show_read: ->
      animationsSvc.highlight_hide_read_button()
      $rootScope.show_read = true
      entriesPaginationSvc.reset_entries()
      $rootScope.feeds_loaded = false
      feedsPaginationSvc.set_busy false
      highlightedSidebarLinkSvc.reset()
      feedsFoldersTimerSvc.load_data()

    #---------------------------------------------
    # Set to false a flag that makes only feeds with unread entries and
    # unread entries to be shown.
    #---------------------------------------------
    hide_read: ->
      animationsSvc.highlight_show_read_button()
      $rootScope.show_read = false
      entriesPaginationSvc.reset_entries()
      $rootScope.feeds_loaded = false
      cleanupSvc.hide_read_feeds()
      feedsPaginationSvc.set_busy false
      highlightedSidebarLinkSvc.reset()
      feedsFoldersTimerSvc.load_data()

  return service
]