########################################################
# AngularJS service to load user configuration data in the scope.
########################################################

angular.module('feedbunch').service 'userDataSvc',
['$rootScope', '$http', '$window', 'timerFlagSvc', 'quickReadingSvc',
($rootScope, $http, $window, timerFlagSvc, quickReadingSvc)->

  #---------------------------------------------
  # Load user configuration data via AJAX into the root scope
  #---------------------------------------------
  load_data: ->
    now = new Date()
    $http.get("/user_data.json?time=#{now.getTime()}")
    .success (data)->
      $rootScope.open_all_entries = data["open_all_entries"]
      $rootScope.quick_reading = data["quick_reading"]
      $rootScope.subscribed_feeds_count = data["subscribed_feeds_count"]
      # Start running Quick Reading mode, if the user has selected it.
      quickReadingSvc.start() if $rootScope.quick_reading
    .error (data, status)->
      if status == 401
        $window.location.href = '/login'
      else if status!=0
        timerFlagSvc.start 'error_loading_user_data'
]