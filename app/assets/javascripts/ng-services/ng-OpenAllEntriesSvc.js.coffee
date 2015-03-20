########################################################
# AngularJS service to lazy load images in entries, when user has configured the app to open all entries by default.
########################################################

angular.module('feedbunch').service 'openAllEntriesSvc',
['$timeout', 'lazyLoadingSvc',
($timeout, lazyLoadingSvc)->

  # Persistent variable to store the scrolling timer
  scrolling_timer = null

  #---------------------------------------------
  # Lazy load images as soon as they are scrolled into the viewport.
  #---------------------------------------------
  start: ->
    $(window).scroll ->
      # Launch handler only 250 ms after user has stopped scrolling, for performance reasons.
      if scrolling_timer
        # If user scrolls again during 250ms after last scroll, reset 250ms timer.
        $timeout.cancel scrolling_timer

      scrolling_timer = $timeout ->
        scrolling_timer = null
        lazyLoadingSvc.load_viewport_images()
      , 250
]