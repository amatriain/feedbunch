########################################################
# AngularJS service to set, unset and recover the currently selected folder in the root scope
########################################################

angular.module('feedbunch').service 'openFolderSvc',
['$rootScope', 'animationsSvc', ($rootScope, animationsSvc)->

  #---------------------------------------------
  # Set the currently open folder in the root scope.
  #---------------------------------------------
  set: (folder)->
    animationsSvc.open_folder folder
    $rootScope.current_open_folder = folder

  #---------------------------------------------
  # Unset the currently open folder in the root scope
  #---------------------------------------------
  unset: ->
    animationsSvc.close_folder $rootScope.current_open_folder
    $rootScope.current_open_folder = null

  #---------------------------------------------
  # Return the folder object which is currently open
  #---------------------------------------------
  get: ->
    $rootScope.current_open_folder
]