########################################################
# AngularJS service to load user configuration in the scope.
########################################################

angular.module('feedbunch').service 'userConfigSvc',
['$rootScope', '$http', 'timerFlagSvc', 'quickReadingSvc', 'openAllEntriesSvc', 'tourSvc', 'keyboardShortcutsSvc',
($rootScope, $http, timerFlagSvc, quickReadingSvc, openAllEntriesSvc, tourSvc, keyboardShortcutsSvc)->

  #---------------------------------------------
  # Load user configuration data via AJAX into the root scope
  #---------------------------------------------
  load_config: ->
    $http.get("/api/user_config.json")
    .success (data)->
      $rootScope.open_all_entries = data["open_all_entries"]
      $rootScope.quick_reading = data["quick_reading"]
      $rootScope.show_main_tour = data["show_main_tour"]
      $rootScope.show_mobile_tour = data["show_mobile_tour"]
      $rootScope.show_feed_tour = data["show_feed_tour"]
      $rootScope.show_entry_tour = data["show_entry_tour"]
      $rootScope.show_kb_shortcuts_tour = data["show_kb_shortcuts_tour"]
      $rootScope.kb_shortcuts_enabled = data["kb_shortcuts_enabled"]
      $rootScope.kb_shortcuts = data["kb_shortcuts"]

      # Start running Quick Reading mode, if the user has selected it.
      quickReadingSvc.start() if $rootScope.quick_reading

      # Start lazy-loading images, if all entries are open by default
      openAllEntriesSvc.start() if $rootScope.open_all_entries

      # Show the main application tour, if the show_main_tour flag is true
      tourSvc.show_main_tour() if $rootScope.show_main_tour

      # Show the mobile application tour, if the show_mobile_tour flag is true
      tourSvc.show_mobile_tour() if $rootScope.show_mobile_tour

      # Start responding to keyboard shortcuts
      keyboardShortcutsSvc.start()
    .error (data, status)->
      timerFlagSvc.start 'error_loading_user_config' if status!=0
]