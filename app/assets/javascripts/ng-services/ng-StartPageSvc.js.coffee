########################################################
# AngularJS service to load the Start page
########################################################

angular.module('feedbunch').service 'startPageSvc',
['$rootScope', '$timeout', 'entriesPaginationSvc', 'menuCollapseSvc',
'sidebarVisibleSvc', 'jobStateSvc',
($rootScope, $timeout, entriesPaginationSvc, menuCollapseSvc,
sidebarVisibleSvc, jobStateSvc)->

  #--------------------------------------------
  # Show the start page
  #--------------------------------------------
  show_start_page: ->
    $rootScope.current_feed = null
    $rootScope.current_folder = null
    entriesPaginationSvc.reset_entries()
    menuCollapseSvc.close()
    jobStateSvc.load_data()
    sidebarVisibleSvc.set false
]