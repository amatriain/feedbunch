########################################################
# AngularJS service to keep track of the state of pagination of entries
########################################################

angular.module('feedbunch').service 'entriesPaginationSvc',
['$rootScope', 'openEntrySvc', ($rootScope, openEntrySvc)->

  #---------------------------------------------
  # Reset the entries list: clear the entries list, unset the currently open entry and reset pagination.
  #---------------------------------------------
  reset_entries: ->
    openEntrySvc.unset()
    $rootScope.entries_page = 0
    $rootScope.entries = []
    $rootScope.load_read_entries = false
    $rootScope.more_entries_available = true
]