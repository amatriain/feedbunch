########################################################
# AngularJS service to set, unset and recover the currently selected folder in the root scope
########################################################

angular.module('feedbunch').service 'openFolderSvc',
['$rootScope', '$timeout', ($rootScope, $timeout)->

  #---------------------------------------------
  # Set the currently open folder in the root scope.
  #---------------------------------------------
  set: (folder)->
    $rootScope.current_open_folder = folder

  #---------------------------------------------
  # Unset the currently open folder in the root scope
  #---------------------------------------------
  unset: ->
    $rootScope.current_open_folder = null

  #---------------------------------------------
  # Return the folder object which is currently open
  #---------------------------------------------
  get: ->
    $rootScope.current_open_folder
]