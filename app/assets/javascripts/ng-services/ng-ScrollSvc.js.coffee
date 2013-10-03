########################################################
# AngularJS service to autoscroll the page under certain events.
# We use JQuery code here. It's a bit ugly to mix it with angularjs
# but it's DEAD SIMPLE and it JUST WORKS.
########################################################

angular.module('feedbunch').service 'scrollSvc',
['$rootScope', ($rootScope)->

  #---------------------------------------------
  # Scroll page to the top
  #---------------------------------------------
  scroll_top: ->
    $('html, body').animate({ scrollTop: 0 }, 300);
]