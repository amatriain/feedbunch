########################################################
# AngularJS service to load user configuration in the scope.
########################################################

angular.module('feedbunch').service 'userConfigSvc',
['$rootScope', '$http', 'timerFlagSvc', 'quickReadingSvc', 'openAllEntriesSvc',
($rootScope, $http, timerFlagSvc, quickReadingSvc, openAllEntriesSvc)->

  #---------------------------------------------
  # Load user configuration data via AJAX into the root scope
  #---------------------------------------------
  load_config: ->
    now = new Date()
    $http.get("/api/user_config.json?time=#{now.getTime()}")
    .success (data)->
      $rootScope.open_all_entries = data["open_all_entries"]
      $rootScope.quick_reading = data["quick_reading"]

      # Start running Quick Reading mode, if the user has selected it.
      quickReadingSvc.start() if $rootScope.quick_reading

      # Start lazy-loading images, if all entries are open by default
      openAllEntriesSvc.start() if $rootScope.open_all_entries
    .error (data, status)->
      timerFlagSvc.start 'error_loading_user_config' if status!=0
]