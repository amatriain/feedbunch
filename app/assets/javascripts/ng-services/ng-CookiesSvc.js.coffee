########################################################
# AngularJS service to manipulate cookies
########################################################

angular.module('feedbunch').service 'cookiesSvc',
['$window', ($window)->

  #---------------------------------------------
  # Set an "accepted_cookies" cookie with value "true". This will make the cookies warning
  # (to comply with EU law) not to appear again.
  #---------------------------------------------
  accept_cookies: ->
    $window.document.cookie = 'accepted_cookies=true; Path=/; Expires=Fri, 31 Dec 9999 23:59:59 GMT'

]