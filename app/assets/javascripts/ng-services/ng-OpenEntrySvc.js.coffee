########################################################
# AngularJS service to set, unset and recover currently opened entries in the root scope.
########################################################

angular.module('feedbunch').service 'openEntrySvc',
['$rootScope', '$timeout', 'animationsSvc', 'tooltipSvc',
($rootScope, $timeout, animationsSvc, tooltipSvc)->

  #--------------------------------------------
  # PRIVATE FUNCTION - Set an entry as closed.
  # Receives as arguments:
  # - entry to close
  #--------------------------------------------
  close = (entry)->
    animationsSvc.close_entry entry
    tooltipSvc.entry_tooltips_hide entry
    index = $rootScope.open_entries.indexOf entry
    $rootScope.open_entries.splice index, 1 if index != -1

  service =

    #---------------------------------------------
    # Set an entry as open.
    # Receives as arguments:
    # - entry to open
    #---------------------------------------------
    open: (entry)->
      animationsSvc.open_entry entry

      # Close any other open entry, unless the user has selected the "open all entries by default" config option
      if $rootScope.open_entries && !$rootScope.open_all_entries
        for e in $rootScope.open_entries
          close e

      # If user has selected to open all entries by default, add the entry to the list of open entries
      if $rootScope.open_entries && $rootScope.open_all_entries
        $rootScope.open_entries.push entry
      # Otherwise there is at most a single open entry.
      else
        $rootScope.open_entries = [entry]

    #---------------------------------------------
    # Set an entry as closed
    #---------------------------------------------
    close: close

    #---------------------------------------------
    # Clear the list of currently open entries. This method does not perform any closing animation;
    # it is assumed that the invoking code will also clear the list of loaded entries, so animations do
    # not make sense.
    #---------------------------------------------
    reset: ->
      $rootScope.open_entries = []

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
      if entries? && entries?.length > 0
        if $rootScope.open_all_entries
          if $rootScope.open_entries?.length > 0
            $rootScope.open_entries = $rootScope.open_entries.concat entries
          else
            $rootScope.open_entries = entries

  return service
]