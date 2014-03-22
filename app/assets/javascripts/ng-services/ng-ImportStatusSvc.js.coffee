########################################################
# AngularJS service to load data import status data in the scope.
########################################################

angular.module('feedbunch').service 'importStatusSvc',
['$rootScope', '$http', '$timeout', 'feedsFoldersSvc', 'timerFlagSvc',
($rootScope, $http, $timeout, feedsFoldersSvc, timerFlagSvc)->

  #---------------------------------------------
  # PRIVATE FUNCTION: load import process status via AJAX
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
  load_import_status = (show_alerts)->
    now = new Date()
    $http.get("/data_imports.json?time=#{now.getTime()}")
    .success (data)->
      # TODO: retrieve show_import_alert from the returned JSON
      $rootScope.show_import_alert = true
      $rootScope.import_status = data["status"]
      if data["status"] == "RUNNING"
        # Update status from the server periodically while import is running
        $rootScope.import_processed = data["import"]["processed"]
        $rootScope.import_total = data["import"]["total"]
        $timeout ->
          load_import_status true
        , 5000
      else if data["status"] == "ERROR" && show_alerts
        timerFlagSvc.start 'error_importing'
      else if data["status"] == "SUCCESS" && show_alerts
        # Automatically load new feeds and folders without needing a refresh
        feedsFoldersSvc.load_data()
        timerFlagSvc.start 'success_importing'

  service =

    #---------------------------------------------
    # Load import process status via AJAX into the root scope
    #---------------------------------------------
    load_data: load_import_status

    #---------------------------------------------
    # Hide the import status alert and notify the server via AJAX that it should not be displayed again.
    #---------------------------------------------
    hide_alert: ->
      $rootScope.show_import_alert = false
      $http.put("/data_imports.json", data_import: {show_alert: 'false'})

  return service
]