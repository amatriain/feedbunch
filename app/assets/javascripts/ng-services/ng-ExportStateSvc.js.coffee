########################################################
# AngularJS service to load data export state data in the scope.
########################################################

angular.module('feedbunch').service 'exportStateSvc',
['$rootScope', '$http', '$timeout', 'feedsFoldersSvc', 'timerFlagSvc',
($rootScope, $http, $timeout, feedsFoldersSvc, timerFlagSvc)->

  #---------------------------------------------
  # PRIVATE FUNCTION: load export process state via AJAX
  #
  # Note.- The first time this is invoked on page load by the angular controller, passing
  # a false to the "show_alerts" argument. This means that if the export is not running
  # (error, success or none, doesn't matter), no alert will be shown.
  #
  # However if the export is found to be running, the function will be called every 5 seconds, with
  # a true to the "show_alerts" argument.
  #
  # Basically this means that if when the page is loaded the export is running, and it finishes
  # afterwards, then and only then will an alert be displayed. Also when this happens new feeds and
  # folders will be inserted in the model automatically.
  #---------------------------------------------
  load_export_state = (show_alerts=false)->
    now = new Date()
    $http.get("/api/opml_exports.json?time=#{now.getTime()}")
    .success (data)->
      $rootScope.show_export_alert = data["show_alert"]
      $rootScope.export_state = data["state"]
      if data["state"] == "RUNNING"
        # Update state from the server periodically while export is running
        $timeout ->
          load_export_state true
        , 5000
      else if data["state"] == "ERROR" && show_alerts
        timerFlagSvc.start 'error_exporting'
      else if data["state"] == "SUCCESS" && show_alerts
        # Automatically load new feeds and folders without needing a refresh
        feedsFoldersSvc.load_data()
        timerFlagSvc.start 'success_exporting'

  service =

    #---------------------------------------------
    # Load export process state via AJAX into the root scope
    #---------------------------------------------
    load_data: load_export_state

    #---------------------------------------------
    # Hide the export state alert and notify the server via AJAX that it should not be displayed again.
    #---------------------------------------------
    hide_alert: ->
      $rootScope.show_export_alert = false
      $http.put("/api/opml_exports.json", opml_export: {show_alert: 'false'})

  return service
]