########################################################
# AngularJS service to load user configuration in the scope.
########################################################

angular.module('feedbunch').service 'userConfigSvc',
['$rootScope', '$http', 'timerFlagSvc', 'quickReadingSvc', 'openAllEntriesSvc', 'tourSvc',
($rootScope, $http, timerFlagSvc, quickReadingSvc, openAllEntriesSvc, tourSvc)->

  #---------------------------------------------
  # Load user configuration data via AJAX into the root scope
  #---------------------------------------------
  load_config: ->
    now = new Date()
    $http.get("/api/user_config.json?time=#{now.getTime()}")
    .success (data)->
      $rootScope.open_all_entries = data["open_all_entries"]
      $rootScope.quick_reading = data["quick_reading"]
      $rootScope.show_main_tour = data["show_main_tour"]
      $rootScope.show_mobile_tour = data["show_mobile_tour"]
      $rootScope.show_feed_tour = data["show_feed_tour"]

      # Start running Quick Reading mode, if the user has selected it.
      quickReadingSvc.start() if $rootScope.quick_reading

      # Start lazy-loading images, if all entries are open by default
      openAllEntriesSvc.start() if $rootScope.open_all_entries

      # Show the main application tour, if the show_main_tour flag is true
      tourSvc.show_main_tour() if $rootScope.show_main_tour

      # Show the mobile application tour, if the show_mobile_tour flag is true
      tourSvc.show_mobile_tour() if $rootScope.show_mobile_tour
    .error (data, status)->
      timerFlagSvc.start 'error_loading_user_config' if status!=0
]