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
    # The fill block is reset to zero height on each entries page load. This fill block is only
    # necessary for the autoscroll when opening an entry to work correctly (positioning the open entry at the top of
    # the list), the rest of the time its height should be zero.
    $('#entries-fill-block').height 0

    $rootScope.current_feed = null
    $rootScope.current_folder = null
    entriesPaginationSvc.reset_entries()
    entriesPaginationSvc.set_busy false
    menuCollapseSvc.close()
    jobStateSvc.load_data()
    sidebarVisibleSvc.set false
]