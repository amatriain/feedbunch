########################################################
# AngularJS service to keep track of the state of pagination of entries
########################################################

angular.module('feedbunch').service 'entriesPaginationSvc',
['$rootScope', 'openEntrySvc', ($rootScope, openEntrySvc)->

  #---------------------------------------------
  # Reset the entries list: clear the entries list, unset the currently open entry and reset pagination.
  #---------------------------------------------
  reset_entries: ->
    openEntrySvc.unset()
    $rootScope.entries_page = 0
    $rootScope.entries = []
    $rootScope.more_entries_available = true
    $rootScope.error_no_entries = false

  #---------------------------------------------
  # Get the AJAX call state: if busy, return true; otherwise return false
  #---------------------------------------------
  is_busy: ->
    return $rootScope.loading_entries_busy

  #---------------------------------------------
  # Set the AJAX call state: true if busy, false otherwise
  #---------------------------------------------
  set_busy: (busy) ->
    $rootScope.loading_entries_busy = busy

  #---------------------------------------------
  # Set whether there are no entries available (server returns a 404)
  #---------------------------------------------
  set_error_no_entries: (error_no_entries) ->
    $rootScope.error_no_entries = error_no_entries

  #---------------------------------------------
  # Get whether there are more entries available in the server (true) or not (false)
  #---------------------------------------------
  more_entries_available: ->
    return $rootScope.more_entries_available

  #---------------------------------------------
  # Set whether there are more entries available in the server (true) or not (false)
  #---------------------------------------------
  set_more_entries_available: (available) ->
    $rootScope.more_entries_available = available

  #---------------------------------------------
  # Get current entries page
  #---------------------------------------------
  get_entries_page: ->
    return $rootScope.entries_page

  #---------------------------------------------
  # Increment current entries page by 1
  #---------------------------------------------
  increment_entries_page: ->
    $rootScope.entries_page += 1

  #---------------------------------------------
  # Get whether the current page is the first (true) or not (false)
  #---------------------------------------------
  is_first_page: ->
    return $rootScope.entries_page == 1
]