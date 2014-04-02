########################################################
# AngularJS service to load in the scope the status of background jobs requested by the user
########################################################

angular.module('feedbunch').service 'jobStatusSvc',
['$rootScope', '$http', '$timeout', 'feedsFoldersSvc', 'timerFlagSvc', 'findSvc',
($rootScope, $http, $timeout, feedsFoldersSvc, timerFlagSvc, findSvc)->

  #---------------------------------------------
  # PRIVATE FUNCTION: load list of job statuses via AJAX
  #---------------------------------------------
  load_refresh_feed_job_statuses = ->
    now = new Date()
    $http.get("/api/refresh_feed_job_statuses.json?time=#{now.getTime()}")
    .success (data)->
      $rootScope.refresh_feed_job_statuses = data.slice()
      for job_status in data
        # Periodically update the status of any running jobs
        load_refresh_feed_job_status job_status.id if job_status.status=="RUNNING"
    .error (data, status)->
      # if HTTP call has been prematurely cancelled, do nothing
      timerFlagSvc.start 'error_loading_job_statuses' if status!=0

  #---------------------------------------------
  # PRIVATE FUNCTION: load status of a single job via AJAX.
  #
  # Receives as argument the id of the job.
  #---------------------------------------------
  load_refresh_feed_job_status = (job_id)->
    $timeout ->
      now = new Date()
      $http.get("/api/refresh_feed_job_statuses/#{job_id}.json?time=#{now.getTime()}")
      .success (data)->
        # Update the current status of the job in the root scope
        job = findSvc.find_refresh_feed_job job_id
        job.status = data.status if job?
        if data.status=="RUNNING"
        # If job is running, keep periodically updating its status
          load_refresh_feed_job_status job_id
        else if data.status=="ERROR"
          timerFlagSvc.start 'error_refreshing_feed'
        else if data.status=="SUCCESS"
          timerFlagSvc.start 'success_refresh_feed'
      .error (data, status)->
        # if HTTP call has been prematurely cancelled, do nothing
        timerFlagSvc.start 'error_loading_job_statuses' if status!=0
    , 5000

  service =

    #---------------------------------------------
    # Load import process status via AJAX into the root scope
    #---------------------------------------------
    load_data: load_refresh_feed_job_statuses

    #---------------------------------------------
    # Hide a job status alert and notify the server via AJAX that it should be deleted from the database
    # (it will not appear again).
    #---------------------------------------------
    hide_alert: (job_status)->
      alert "not yet implemented"
    # TODO: NOT YET IMPLEMENTED
    #  $rootScope.show_import_alert = false
    #  $http.put("/api/data_imports.json", data_import: {show_alert: 'false'})

  return service
]