########################################################
# AngularJS service to manipulate cookies
########################################################

angular.module('feedbunch').service 'cookiesSvc',
['$cookies', ($cookies)->

  #---------------------------------------------
  # Set an "accepted_cookies" cookie with value "true". This will make the cookies warning
  # (to comply with EU law) not to appear again.
  #---------------------------------------------
  accept_cookies: ->
    $cookies.accepted_cookies = 'true'

]