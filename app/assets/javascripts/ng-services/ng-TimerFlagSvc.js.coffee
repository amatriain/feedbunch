########################################################
# AngularJS service to set a boolean flag as true and then 5 seconds later set it as false
########################################################

angular.module('feedbunch').service 'timerFlagSvc',
['$rootScope', '$timeout',
($rootScope, $timeout)->

  #--------------------------------------------
  # PRIVATE FUNCTION: Stop a running timer.
  #--------------------------------------------
  stop_timer = (flag)->
    timer = $rootScope.alert_timers[flag]
    if timer
      $timeout.cancel timer
      delete $rootScope.alert_timers[flag]

  service =

    #---------------------------------------------
    # Set a boolean flag in the root scope as true, and 5 seconds later set it as false.
    # The flag name must be passed as a string argument.
    #---------------------------------------------
    start: (flag)->
      # Store running timers in a hash in the root scope
      $rootScope.alert_timers ||= {}
      stop_timer flag
      eval "$rootScope.#{flag} = true"
      timer = $timeout ->
        eval "$rootScope.#{flag} = false"
        delete $rootScope.alert_timers[flag]
      , 5000
      $rootScope.alert_timers[flag] = timer

    #---------------------------------------------
    # Set a boolean flag in the root scope as false.
    # The flag name must be passed as a string argument.
    #---------------------------------------------
    reset: (flag)->
      # Set flag as false immediately
      eval "$rootScope.#{flag} = false"
      # Stop the running timer that would set the flag as false after 5 seconds
      stop_timer flag

  return service
]