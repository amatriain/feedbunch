########################################################
# AngularJS service to set and recover the currently selected folder in the root scope
########################################################

angular.module('feedbunch').service 'currentFolderSvc',
['$rootScope', 'entriesPaginationSvc', 'cleanupSvc', 'findSvc', 'openFolderSvc',
($rootScope, entriesPaginationSvc, cleanupSvc, findSvc, openFolderSvc)->

  set: (folder)->
    entriesPaginationSvc.reset_entries()
    $rootScope.current_feed = null
    if folder=="all"
      $rootScope.current_folder = {id: "all"}
    else
      # Open the folder if it isn't already open.
      openFolderSvc.set folder
      $rootScope.current_folder = folder
    cleanupSvc.hide_read_feeds()

  get: ->
    return findSvc.find_folder $rootScope.current_folder?.id
]