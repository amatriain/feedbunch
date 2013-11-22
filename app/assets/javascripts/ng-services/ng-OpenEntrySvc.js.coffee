########################################################
# AngularJS service to set, unset and recover currently opened entries in the root scope.
########################################################

angular.module('feedbunch').service 'openEntrySvc',
['$rootScope', '$location', '$anchorScroll',
($rootScope, $location, $anchorScroll)->

  #---------------------------------------------
  # Set the currently open entry
  #---------------------------------------------
  set: (entry)->
    $rootScope.open_entries = [entry]
    # Scroll so that the entry link is at the top of the viewport, for maximum visibility of
    # the entry body
    $location.hash "entry-#{entry.id}-anchor"
    $anchorScroll()

  #---------------------------------------------
  # Unset the currently open entry
  #---------------------------------------------
  unset: ->
    $rootScope.open_entries = []
    $location.hash('')

  #---------------------------------------------
  # Get the currently open entry
  #---------------------------------------------
  get: ->
    if $rootScope.open_entries?.length > 0
      return $rootScope.open_entries[0]
    else
      return null

  #---------------------------------------------
  # Return true if the passed entry is open, false otherwise
  #---------------------------------------------
  is_open: (entry)->
    if $rootScope.open_entries?.length > 0
      return $rootScope.open_entries[0].id==entry.id
    else
      return false
]