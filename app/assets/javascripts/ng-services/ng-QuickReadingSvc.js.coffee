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
        $('div#feed-entries a[data-entry-id]:above-the-top(35)').each (index)->
          alert $(this).attr('data-entry-id')
      , 500
]