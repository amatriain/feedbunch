########################################################
# AngularJS service to set, unset and recover the currently selected folder in the root scope
########################################################

angular.module('feedbunch').service 'openFolderSvc',
['$rootScope', ($rootScope)->

  set: (folder)->
    $rootScope.current_open_folder = folder

  unset: ->
    $rootScope.current_open_folder = null

  get: ->
    $rootScope.current_open_folder
]