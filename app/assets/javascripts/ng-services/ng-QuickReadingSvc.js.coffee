########################################################
# AngularJS service to mark entries as read as soon as they are scrolled above the viewport
########################################################

angular.module('feedbunch').service 'quickReadingSvc',
['$rootScope', '$timeout',
($rootScope, $timeout)->

  #---------------------------------------------
  # Start marking entries as read as soon as they are scrolled above the viewport.
  #---------------------------------------------
  start: ->
    $(window).scroll ->
      # Launch handler only 500 ms after user has stopped scrolling, for performance reasons.
      if $rootScope.scrolling_timer
        $timeout.cancel $rootScope.scrolling_timer
      $rootScope.scrolling_timer = $timeout ->
        delete $rootScope.scrolling_timer
        $('a[data-entry-id]').not($('a[data-entry-id]').withinViewportTop({top: 15})).each ->
          alert $(this).attr 'data-entry-id'
      , 500
]