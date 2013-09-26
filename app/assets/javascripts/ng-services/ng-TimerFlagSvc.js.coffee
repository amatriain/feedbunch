########################################################
# AngularJS service to set a boolean flag as true and then 5 seconds later set it as false
########################################################

angular.module('feedbunch').service 'timerFlagSvc',
['$rootScope', '$timeout', ($rootScope, $timeout)->

  #---------------------------------------------
  # Set a boolean flag in the root scope as true, and 5 seconds later set it as false.
  # The flag name must be passed as a string argument.
  #---------------------------------------------
  start: (flag)->
    eval "$rootScope.#{flag} = true"
    $timeout ->
      eval "$rootScope.#{flag} = false"
    , 5000
]