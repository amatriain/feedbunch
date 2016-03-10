########################################################
# AngularJS service to set, unset and recover the currently selected folder in the root scope
########################################################

angular.module('feedbunch').service 'openFolderSvc',
['$rootScope', 'animationsSvc', ($rootScope, animationsSvc)->

  #--------------------------------------------
  # PRIVATE FUNCTION: Unset the current open folder, making all folders closed
  #--------------------------------------------
  unset = ->
    animationsSvc.close_folder $rootScope.current_open_folder
    $rootScope.current_open_folder = null

  #--------------------------------------------
  # PRIVATE FUNCTION:Set the current open folder, making it the only one open
  #--------------------------------------------
  set = (folder)->
    if folder.id != $rootScope.current_open_folder?.id
      animationsSvc.open_folder folder
      # When opening a folder, close any other open folder
      if $rootScope.current_open_folder?
        animationsSvc.close_folder $rootScope.current_open_folder
      $rootScope.current_open_folder = folder

  service =

    #---------------------------------------------
    # Set the currently open folder in the root scope.
    #---------------------------------------------
    set: set

    #---------------------------------------------
    # Unset the currently open folder in the root scope
    #---------------------------------------------
    unset: unset

    #---------------------------------------------
    # Return the folder object which is currently open
    #---------------------------------------------
    get: ->
      $rootScope.current_open_folder

    #--------------------------------------------
    # Toggle open folder in the root scope.
    #--------------------------------------------
    toggle_open_folder: (folder)->
      if $rootScope.current_open_folder?.id == folder.id
        # User is closing the open folder
        unset()
      else
        set folder

  return service
]
