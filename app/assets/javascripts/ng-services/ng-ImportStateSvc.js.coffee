########################################################
# AngularJS service to load data import state data in the scope.
########################################################

angular.module('feedbunch').service 'importStateSvc',
['$rootScope', '$http', '$timeout', 'feedsFoldersSvc', 'timerFlagSvc',
($rootScope, $http, $timeout, feedsFoldersSvc, timerFlagSvc)->

  #---------------------------------------------
  # PRIVATE FUNCTION: load import process state via AJAX
  #
  # Note.- The first time this is invoked on page load by the angular controller, passing
  # a false to the "show_alerts" argument. This means that if the import is not running
  # (error, success or none, doesn't matter), no alert will be shown.
  #
  # However if the import is found to be running, the function will be called every 5 seconds, with
  # a true to the "show_alerts" argument.
  #
  # Basically this means that if when the page is loaded the import is running, and it finishes
  # afterwards, then and only then will an alert be displayed. Also when this happens new feeds and
  # folders will be inserted in the model automatically.
  #---------------------------------------------
  load_import_state = (show_alerts)->
    now = new Date()
    $http.get("/api/opml_imports.json?time=#{now.getTime()}")
    .success (data)->
      $rootScope.show_import_alert = data["show_alert"]
      $rootScope.import_state = data["state"]
      if data["state"] == "RUNNING"
        # Update state from the server periodically while import is running
        $rootScope.import_processed = data["import"]["processed"]
        $rootScope.import_total = data["import"]["total"]
        $timeout ->
          load_import_state true
        , 5000
      else if data["state"] == "ERROR" && show_alerts
        timerFlagSvc.start 'error_importing'
      else if data["state"] == "SUCCESS" && show_alerts
        # Automatically load new feeds and folders without needing a refresh
        feedsFoldersSvc.load_data()
        timerFlagSvc.start 'success_importing'

  service =

    #---------------------------------------------
    # Load import process state via AJAX into the root scope
    #---------------------------------------------
    load_data: load_import_state

    #---------------------------------------------
    # Hide the import state alert and notify the server via AJAX that it should not be displayed again.
    #---------------------------------------------
    hide_alert: ->
      $rootScope.show_import_alert = false
      $http.put("/api/opml_imports.json", opml_import: {show_alert: 'false'})

  return service
]