########################################################
# AngularJS service to manage entries
########################################################

angular.module('feedbunch').service 'entrySvc',
['$rootScope', '$http', 'openEntrySvc', 'timerFlagSvc', 'unreadCountSvc',
($rootScope, $http, openEntrySvc, timerFlagSvc, unreadCountSvc)->

  #--------------------------------------------
  # PRIVATE FUNCTION - Mark an array of entries as read or unread.
  # Receives as arguments an array of entries and a boolean indicating whether to mark
  # them as read (true) or unread (false).
  #--------------------------------------------
  change_entries_state = (entries, read)->
    # Mark entries as read or unread in the model
    for entry in entries
      entry.read = read
      entry.changing_state = true

    # Get array of IDs for the entries
    entry_ids = entries.map (entry) -> entry.id

    if read
      state = "read"
      unreadCountSvc.update_unread_count entries, false
    else
      state = "unread"
      unreadCountSvc.update_unread_count entries, true

    $http.put("/entries/update.json", entries: {ids: entry_ids, state: state})
    .success ->
      for entry in entries
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
          change_entries_state [entry], true

    #--------------------------------------------
    # Mark all entries as read
    #--------------------------------------------
    mark_all_read: ->
      change_entries_state $rootScope.entries, true

    #--------------------------------------------
    # Mark a single entry as unread
    #--------------------------------------------
    unread_entry: ->
      if openEntrySvc.get().read
        change_entries_state [openEntrySvc.get()], false

  return service
]