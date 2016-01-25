########################################################
# AngularJS service to mark entries as read as soon as they are scrolled above the viewport
########################################################

angular.module('feedbunch').service 'quickReadingSvc',
['$rootScope', '$timeout', 'findSvc', 'entrySvc',
($rootScope, $timeout, findSvc, entrySvc)->

  # Persistent variable to store the scrolling timer
  scrolling_timer = null

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

        # mark as read entries that are in the array before the first currently visible entry
        first_entry_id = $('a[data-entry-id]:in-viewport').first().attr 'data-entry-id'
        if first_entry_id?
          first_entry = findSvc.find_entry first_entry_id
          first_entry_index = $rootScope.entries.indexOf first_entry
          if first_entry_index != -1
            entries_before = $rootScope.entries[0...first_entry_index]
            for entry in entries_before
              entrySvc.read_entry entry unless entry.read
        end

      , 250
]