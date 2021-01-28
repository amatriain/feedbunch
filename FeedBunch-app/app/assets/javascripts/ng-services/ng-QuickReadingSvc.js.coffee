########################################################
# AngularJS service to mark entries as read as soon as they are scrolled above the viewport
########################################################

angular.module('feedbunch').service 'quickReadingSvc',
['$rootScope', '$timeout', 'findSvc', 'entrySvc',
($rootScope, $timeout, findSvc, entrySvc)->

  # Persistent variable to store the scrolling timer
  scrolling_timer = null

  #--------------------------------------------
  # PRIVATE FUNCTION - find the index in the global entries list of the last entry above the viewport.
  # If there are entry links in the viewport, returns the index of the entry immediately before the first visible one
  # (or -1 if there are no entries before).
  # Otherwise, if there is an entry content in the viewport, returns the index of that entry.
  # If there are neither entry links nor entry contents in the viewport, returns -1.
  #--------------------------------------------
  find_last_entry_above_viewport = ->
    first_entry_id = $('a[data-entry-id]:in-viewport').first().attr 'data-entry-id'
    if first_entry_id?
      # There are entry links in the viewport
      first_entry = findSvc.find_entry first_entry_id
      first_entry_index = $rootScope.entries.indexOf first_entry
      unless first_entry_index > 0
        # There are no entries above the viewport
        return -1
      last_entry_index = first_entry_index - 1
    else
      # There are no entry links in the viewport
      entry_content = $('div.entry-content:in-viewport')
      if entry_content
        # There is an open entry content in the viewport
        open_entry_id = entry_content.parent().prev('a[data-entry-id]').attr 'data-entry-id'
        open_entry = findSvc.find_entry open_entry_id
        last_entry_index = $rootScope.entries.indexOf open_entry
      else
        # There is neither entry links nor entry contents in the viewport
        return -1

    return last_entry_index

  service =

    #---------------------------------------------
    # Start marking entries as read as soon as they are scrolled above the viewport.
    #---------------------------------------------
    start: ->
      $(window).scroll ->
        # Launch handler only 250 ms after user has stopped scrolling, for performance reasons.
        if scrolling_timer
          # If user scrolls again during 250ms after last scroll, reset 250ms timer.
          $timeout.cancel scrolling_timer

        scrolling_timer = $timeout ->
          scrolling_timer = null

          # mark as read all entries above the viewport
          last_entry_index = find_last_entry_above_viewport()
          if last_entry_index != -1
            entries_above = $rootScope.entries[0..last_entry_index]
            for entry in entries_above
              entrySvc.read_entry entry unless entry.read

        , 250

  return service
]