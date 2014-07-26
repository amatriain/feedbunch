########################################################
# AngularJS service to scroll the page.
########################################################

angular.module('feedbunch').service 'scrollSvc',
['$timeout',
($timeout)->

  #---------------------------------------------
  # Smoothly scroll the page until an entry link is almost at the top,
  # with another entry partially visible above.
  # Receives an entry as argument.
  #---------------------------------------------
  scrollToEntry: (entry)->
    # Scroll so that the entry link is at the top of the viewport, for maximum visibility of
    # the entry body.
    # We introduce a small delay before scrolling to give angularjs time to close any other entries, so that
    # the entry top has its final position after any entry closing animations.
    target = $("#entry-#{entry.id}")
    # We leave an offset so that part of the entry above is still visible under the navbar.
    topOffset = 100
    $timeout ->
      $('html,body').animate {scrollTop: target.offset().top - topOffset}, 200
    , 150

]