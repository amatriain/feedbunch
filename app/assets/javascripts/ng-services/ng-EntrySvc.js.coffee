########################################################
# AngularJS service to manage entries
########################################################

angular.module('feedbunch').service 'entrySvc',
['$rootScope', '$http', 'openEntrySvc', 'timerFlagSvc', 'unreadCountSvc',
($rootScope, $http, openEntrySvc, timerFlagSvc, unreadCountSvc)->

  #--------------------------------------------
  # PRIVATE FUNCTION - Mark a single entry as read or unread.
  # Receives as arguments an entry and a boolean indicating whether to mark
  # it as read (true) or unread (false).
  #--------------------------------------------
  change_entry_state = (entry, read)->
    # Mark entry as read or unread in the model
    entry.read = read
    entry.changing_state = true

    if read
      state = "read"
      unreadCountSvc.update_unread_count entry, false
    else
      state = "unread"
      unreadCountSvc.update_unread_count entry, true

    $http.put("/entries/update.json", entry: {id: entry.id, state: state})
    .success ->
      entry.changing_state = false
    .error ->
      timerFlagSvc.start 'error_changing_entry_state'

  #--------------------------------------------
  # PRIVATE FUNCTION - Mark all entries from a feed as read .
  # Receives as arguments a feed.
  #--------------------------------------------
  change_entries_read = (feed)->
    # Mark entries as read in the model
    first_entry = $rootScope.entries[0]
    for entry in $rootScope.entries
      entry.read = true
      entry.changing_state = true

    unreadCountSvc.zero_unread_count feed

    $http.put("/entries/update.json", entry: {id: first_entry.id, state: 'read', update_older: 'true'})
    .success ->
      for entry in $rootScope.entries
        entry.changing_state = false
    .error ->
      timerFlagSvc.start 'error_changing_entry_state'

  service =

    #--------------------------------------------
    # Mark a single entry as read
    #--------------------------------------------
    read_entry: (entry)->
      if openEntrySvc.get() == entry
        # User is closing the open entry, do nothing
        openEntrySvc.unset()
      else
        openEntrySvc.set entry
        if !entry.read
          # User is opening an unread entry, mark it as read
          change_entry_state entry, true

    #--------------------------------------------
    # Mark all entries as read
    #--------------------------------------------
    mark_all_read: ->
      change_entries_read $rootScope.current_feed

    #--------------------------------------------
    # Mark a single entry as unread
    #--------------------------------------------
    unread_entry: ->
      if openEntrySvc.get()
        change_entry_state openEntrySvc.get(), false if openEntrySvc.get().read

  return service
]