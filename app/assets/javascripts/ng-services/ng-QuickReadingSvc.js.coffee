########################################################
# AngularJS service to mark entries as read as soon as they are scrolled above the viewport
########################################################

angular.module('feedbunch').service 'quickReadingSvc',
['$timeout', 'findSvc', 'entrySvc',
($timeout, findSvc, entrySvc)->

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
        $('a[data-entry-id].entry-unread').each ->
          if $(this).is ':in-viewport'
            id = $(this).attr 'data-entry-id'
            entry = findSvc.find_entry id
            entrySvc.read_entry entry
      , 250
]