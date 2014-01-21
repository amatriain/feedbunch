########################################################
# AngularJS service to set, unset and recover the currently selected folder in the root scope
########################################################

angular.module('feedbunch').service 'currentFolderSvc',
['$rootScope', 'entriesPaginationSvc', 'cleanupSvc', 'findSvc', 'sidebarVisibleSvc', 'menuCollapseSvc',
($rootScope, entriesPaginationSvc, cleanupSvc, findSvc, sidebarVisibleSvc, menuCollapseSvc)->

  set: (folder)->
    entriesPaginationSvc.reset_entries()
    $rootScope.current_feed = null
    if folder=="all"
      $rootScope.current_folder = {id: "all"}
    else
      $rootScope.current_folder = folder
    cleanupSvc.hide_read_feeds()
    sidebarVisibleSvc.toggle()
    menuCollapseSvc.close()

  unset: ->
    entriesPaginationSvc.reset_entries()
    $rootScope.current_folder = null

  get: ->
    return findSvc.find_folder $rootScope.current_folder?.id
]