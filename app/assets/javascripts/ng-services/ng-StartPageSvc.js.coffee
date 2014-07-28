########################################################
# AngularJS service to load the Start page
########################################################

angular.module('feedbunch').service 'startPageSvc',
['$rootScope', '$timeout', 'currentFeedSvc', 'currentFolderSvc', 'entriesPaginationSvc', 'menuCollapseSvc',
'sidebarVisibleSvc', 'jobStateSvc',
($rootScope, $timeout, currentFeedSvc, currentFolderSvc, entriesPaginationSvc, menuCollapseSvc,
sidebarVisibleSvc, jobStateSvc)->

  #--------------------------------------------
  # Show the start page
  #--------------------------------------------
  show_start_page: ->
    currentFeedSvc.unset()
    currentFolderSvc.unset()
    entriesPaginationSvc.set_busy false
    menuCollapseSvc.close()
    jobStateSvc.load_data()
    sidebarVisibleSvc.set false
]