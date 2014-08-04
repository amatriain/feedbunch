########################################################
# AngularJS service to set, unset and recover currently opened entries in the root scope.
########################################################

angular.module('feedbunch').service 'openEntrySvc',
['$rootScope', '$location', '$timeout', 'scrollSvc', 'animationsSvc',
($rootScope, $location, $timeout, scrollSvc, animationsSvc)->

  #---------------------------------------------
  # Set an entry as open
  #---------------------------------------------
  open: (entry)->
    # If user has selected to open all entries by default, add the entry to the list of open entries
    if $rootScope.open_entries && $rootScope.open_all_entries
      $rootScope.open_entries.push entry
    # Otherwise there is at most a single open entry.
    else
      $rootScope.open_entries = [entry]

    animationsSvc.open_entry entry
    scrollSvc.scrollToEntry entry
    
  #---------------------------------------------
  # Set an entry as closed
  #---------------------------------------------
  close: (entry)->
    index = $rootScope.open_entries.indexOf entry
    $rootScope.open_entries.splice index, 1 if index != -1
    animationsSvc.close_entry entry

  #---------------------------------------------
  # Reset the entries open/close state. If the user has selected the "open all entries" option for
  # his profile, all entries will be open. Otherwise no entry will be open
  #---------------------------------------------
  reset: ->
    $rootScope.open_entries = []
    $location.hash('')

  #---------------------------------------------
  # Return true if the passed entry is open, false otherwise
  #---------------------------------------------
  is_open: (entry)->
    if $rootScope.open_entries
      return entry in $rootScope.open_entries
    else
      return false

  #---------------------------------------------
  # Set the correct state (open/close) for newly loaded entries. If the user has selected the "open all entries" checkbox,
  # all new entries are initially open. Otherwise all new entries are initially closed.
  # Receives as argument an array of entries
  #---------------------------------------------
  add_entries: (entries)->
    if $rootScope.open_all_entries
      if $rootScope.open_entries?.length > 0
        $rootScope.open_entries = $rootScope.open_entries.concat entries
      else
        $rootScope.open_entries = entries
]