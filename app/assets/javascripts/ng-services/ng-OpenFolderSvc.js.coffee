########################################################
# AngularJS service to set, unset and recover the currently selected folder in the root scope
########################################################

angular.module('feedbunch').service 'openFolderSvc',
['$rootScope', ($rootScope)->

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
  # Set the currently open folder in the root scope, and also
  # display its entries.
  # This method uses jquery and boostrap code, it's not pure angularjs but it gets the job done.
  # There should be no need to invoke this method when user is clicking on a folder to open it,
  # only when a folder is opened programatically.
  #---------------------------------------------
  open: (folder)->
    $rootScope.current_open_folder = folder
    $rootScope.$apply()
    $("#feeds-#{folder.id}").collapse 'show'
    # close all other folders
    for f in $rootScope.folders
      $("#feeds-#{f.id}").collapse 'hide' if f != folder

  #---------------------------------------------
  # Unset the currently open folder in the root scope, and also
  # close all folders.
  # This method uses jquery and boostrap code, it's not pure angularjs but it gets the job done.
  # There should be no need to invoke this method when user is clicking on a folder to open it,
  # only when folders are closed programatically.
  #---------------------------------------------
  close_all: ->
    $rootScope.current_open_folder = null
    $rootScope.$apply()
    # close all folders
    for f in $rootScope.folders
      $("#feeds-#{f.id}").collapse 'hide'

  #---------------------------------------------
  # Return the folder object which is currently open
  #---------------------------------------------
  get: ->
    $rootScope.current_open_folder
]