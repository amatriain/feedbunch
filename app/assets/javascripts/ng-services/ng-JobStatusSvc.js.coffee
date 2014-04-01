########################################################
# AngularJS service to load in the scope the status of background jobs requested by the user
########################################################

angular.module('feedbunch').service 'jobStatusSvc',
['$rootScope', '$http', '$timeout', 'feedsFoldersSvc', 'timerFlagSvc',
($rootScope, $http, $timeout, feedsFoldersSvc, timerFlagSvc)->

  #---------------------------------------------
  # PRIVATE FUNCTION: load job statuses via AJAX
  #
  # Note.- The first time this is invoked when opening the start page, passing
  # a false to the "show_alerts" argument. This means that if a job is not running
  # when the start page is opened, no alert will be shown for the job.
  #
  # However if a job is found to be running, the function will be called every 5 seconds, with
  # a true to the "show_alerts" argument.
  #
  # Basically this means that if when the start page is opened a job is running, and it finishes
  # afterwards, then and only then will an alert be displayed. Depending on the job, this may mean
  # that feeds are automatically added or removed from the root scope.
  #---------------------------------------------
  load_refresh_feed_job_statuses = (show_alerts)->
    now = new Date()
    $http.get("/api/refresh_feed_job_statuses.json?time=#{now.getTime()}")
    .success (data)->
      $rootScope.refresh_feed_job_statuses = data["job_statuses"]
      job_running = false
      for job_status in job_statuses
        job_running = true if job_status.status == "RUNNING"
        # TODO implement refresh error and success alerts for every job?
      if job_running
        # Update status from the server periodically while any job is running
        $timeout ->
          load_refresh_feed_job_statuses true
        , 2000
      #else if data["status"] == "ERROR" && show_alerts
        #timerFlagSvc.start 'error_importing'
      #else if data["status"] == "SUCCESS" && show_alerts
        # Automatically load new feeds and folders without needing a refresh
        #feedsFoldersSvc.load_data()
        #timerFlagSvc.start 'success_importing'

  service =

    #---------------------------------------------
    # Load import process status via AJAX into the root scope
    #---------------------------------------------
    load_data: load_refresh_feed_job_statuses

    #---------------------------------------------
    # Hide a job status alert and notify the server via AJAX that it should be deleted from the database
    # (it will not appear again).
    #---------------------------------------------
    # TODO: NOT YET IMPLEMENTED
    #hide_alert: ->
    #  $rootScope.show_import_alert = false
    #  $http.put("/api/data_imports.json", data_import: {show_alert: 'false'})

  return service
]