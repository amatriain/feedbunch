########################################################
# AngularJS service to lazy load images in entries, when user has configured the app to open all entries by default.
########################################################

angular.module('feedbunch').service 'openAllEntriesSvc',
['$rootScope', '$timeout', 'lazyLoadingSvc',
($rootScope, $timeout, lazyLoadingSvc)->

  #---------------------------------------------
  # Lazy load images as soon as they are scrolled into the viewport.
  #---------------------------------------------
  start: ->
    $(window).scroll ->
      # Launch handler only 250 ms after user has stopped scrolling, for performance reasons.
      if $rootScope.scrolling_timer
        # If user scrolls again during 250ms after last scroll, reset 250ms timer.
        $timeout.cancel $rootScope.scrolling_timer

      $rootScope.scrolling_timer = $timeout ->
        delete $rootScope.scrolling_timer
        lazyLoadingSvc.load_viewport_images()
      , 250
]