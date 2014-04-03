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
      # if HTTP call has been prematurely cancelled or there's simply no job statuses, do nothing
      timerFlagSvc.start 'error_loading_job_statuses' if status!=0 && status!=404

  #---------------------------------------------
  # PRIVATE FUNCTION: load status of a single job via AJAX.
  #
  # Receives as argument the id of the job.
  #---------------------------------------------
  load_refresh_feed_job_status = (job_id)->
    # Store running timers in a hash in the root scope
    $rootScope.refresh_job_status_timers ||= {}

    # Only start a timer to refresh the job status if there isn't a timer already refreshing that job status
    timer = $rootScope.refresh_job_status_timers[job_id]
    if !timer?
      timer = $timeout ->
        # Remove this timer from the list so that another update can be scheduled for 5 seconds in the future
        delete $rootScope.refresh_job_status_timers[job_id]
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
            feedsFoldersSvc.load_feed job.feed_id
        .error (data, status)->
          # if HTTP call has been prematurely cancelled, do nothing
          timerFlagSvc.start 'error_loading_job_statuses' if status!=0 && status!=404
      , 5000
      # Store timer so that a second timer for the same job status is not started in the future
      $rootScope.refresh_job_status_timers[job_id] = timer

  service =

    #---------------------------------------------
    # Load import process status via AJAX into the root scope
    #---------------------------------------------
    load_data: load_refresh_feed_job_statuses

    #---------------------------------------------
    # Hide a refresh feed job status alert and notify the server via AJAX that it should be deleted
    # from the database (it will not appear again).
    #---------------------------------------------
    hide_refresh_job_alert: (job_status)->
      # Remove job status from scope
      job_status = findSvc.find_refresh_feed_job job_status.id
      if job_status?
        index = $rootScope.refresh_feed_job_statuses.indexOf job_status
        $rootScope.refresh_feed_job_statuses.splice index, 1 if index != -1

      # If there is a timer updating this job status, stop it.
      if $rootScope.refresh_job_status_timers?
        timer = $rootScope.refresh_job_status_timers[job_status.id]
        if timer?
          $timeout.cancel timer
          delete $rootScope.refresh_job_status_timers[job_status.id]

      $http.delete "/api/refresh_feed_job_statuses/#{job_status.id}.json"

  return service
]