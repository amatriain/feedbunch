########################################################
# AngularJS service to set, unset and recover the currently selected folder in the root scope
########################################################

angular.module('feedbunch').service 'currentFolderSvc',
['$rootScope', ($rootScope)->

  set: (folder)->
    $rootScope.current_feed = null
    $rootScope.open_entry = null
    $rootScope.entries_page = 0
    $rootScope.entries = []
    $rootScope.current_folder = folder

  unset: ->
    $rootScope.open_entry = null
    $rootScope.current_folder = null

  get: ->
    $rootScope.current_folder
]