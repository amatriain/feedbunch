########################################################
# AngularJS service to manage entries
########################################################

angular.module('feedbunch').service 'entrySvc',
['$rootScope', '$http', '$window', 'openEntrySvc', 'timerFlagSvc', 'unreadCountSvc',
'currentFolderSvc', 'currentFeedSvc', 'findSvc', 'readSvc',
($rootScope, $http, $window, openEntrySvc, timerFlagSvc, unreadCountSvc,
currentFolderSvc, currentFeedSvc, findSvc, readSvc)->

  #--------------------------------------------
  # PRIVATE FUNCTION - Mark a single entry as read or unread.
  # Receives as arguments an entry and a boolean indicating whether to mark
  # it as read (true) or unread (false).
  #
  # It also optionally receives a feed ID;  if received, invoke the read_feed
  # private function after the entry has changed state in the server.
  #--------------------------------------------
  change_entry_state = (entry, read, feed_id = null)->
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
      read_feed feed_id if feed_id?
    .error (data, status)->
      if status == 401
        $window.location.href = '/login'
      else if status!=0
        timerFlagSvc.start 'error_changing_entry_state'

  #--------------------------------------------
  # PRIVATE FUNCTION - Set the feed with the passed ID as the currently selected one, and
  # load its list of entries
  #--------------------------------------------
  read_feed = (feed_id)->
    feed = findSvc.find_feed feed_id
    if feed?
      currentFeedSvc.set feed
      readSvc.read_entries_page()

  #--------------------------------------------
  # PRIVATE FUNCTION - Mark all entries in the currently selected feed or folder as read.
  #--------------------------------------------
  change_entries_read = ->
    if $rootScope.entries && $rootScope.entries?.length > 0
      # Mark entries as read in the model
      first_entry = $rootScope.entries[0]
      for entry in $rootScope.entries
        entry.read = true
        entry.changing_state = true

      # Find out if the user wants to mark as read a whole feed, a whole folder, or all entries in
      # all subscribed feeds.
      current_feed = currentFeedSvc.get()
      current_folder = currentFolderSvc.get()
      if current_feed
        whole_feed = "true"
        whole_folder = "false"
        all_entries = "false"
        unreadCountSvc.zero_feed_count current_feed.id
      else if current_folder && current_folder?.id != "all"
        whole_feed = "false"
        whole_folder = "true"
        all_entries = "false"
        unreadCountSvc.zero_folder_count current_folder
      else if current_folder && current_folder?.id == "all"
        whole_feed = "false"
        whole_folder = "false"
        all_entries = "true"
        unreadCountSvc.zero_folder_count 'all'
      else
        return

      $http.put("/entries/update.json", entry: {id: first_entry.id, state: 'read', whole_feed: whole_feed, whole_folder: whole_folder, all_entries: all_entries})
      .success ->
        for entry in $rootScope.entries
          entry.changing_state = false
      .error (data, status)->
        if status == 401
          $window.location.href = '/login'
        else if status!=0
          timerFlagSvc.start 'error_changing_entry_state'

  service =

    #--------------------------------------------
    # Set (if opening) or unset (if closing) the currently open entry. If opening, mark it as read.
    #--------------------------------------------
    toggle_open_entry: (entry)->
      if openEntrySvc.is_open entry
        # User is closing the open entry
        openEntrySvc.close entry
      else
        openEntrySvc.open entry
        if !entry.read
          # User is opening an unread entry, mark it as read
          change_entry_state entry, true

    #--------------------------------------------
    # Mark a single entry as unread
    #--------------------------------------------
    read_entry: (entry)->
      change_entry_state entry, true if !entry.read

    #--------------------------------------------
    # Mark a single entry as unread
    #--------------------------------------------
    unread_entry: (entry)->
      change_entry_state entry, false if entry.read

    #--------------------------------------------
    # Mark all entries as read
    #--------------------------------------------
    mark_all_read: ->
      change_entries_read()

    #--------------------------------------------
    # Return the title of the feed to which an entry belongs
    #--------------------------------------------
    entry_feed_title: (entry)->
      feed = findSvc.find_feed entry.feed_id
      if feed
        return feed.title
      else
        return ''

    #--------------------------------------------
    # Mark an entry as unread and load its feed's list of entries
    #--------------------------------------------
    load_entry_feed: (entry)->
      change_entry_state entry, false, entry.feed_id

  return service
]