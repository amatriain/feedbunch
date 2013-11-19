########################################################
# AngularJS service to mark entries as read as soon as they are scrolled above the viewport
########################################################

angular.module('feedbunch').service 'quickReadingSvc',
['$rootScope', '$timeout', 'findSvc', 'entrySvc',
($rootScope, $timeout, findSvc, entrySvc)->

  #---------------------------------------------
  # Start marking entries as read as soon as they are scrolled above the viewport.
  #---------------------------------------------
  start: ->
    $(window).scroll ->
      # Launch handler only 500 ms after user has stopped scrolling, for performance reasons.
      if $rootScope.scrolling_timer
        # If user scrolls again during 500ms after last scroll, reset 500ms timer.
        $timeout.cancel $rootScope.scrolling_timer

      $rootScope.scrolling_timer = $timeout ->
        delete $rootScope.scrolling_timer

        # Select entries above the viewport.
        $('a[data-entry-id]').not($('a[data-entry-id]').withinViewportTop({top: 15})).each ->
          if $(this).hasClass 'entry-unread'
            id = $(this).attr 'data-entry-id'
            entry = findSvc.find_entry id
            entrySvc.read_entry entry
      , 500
]