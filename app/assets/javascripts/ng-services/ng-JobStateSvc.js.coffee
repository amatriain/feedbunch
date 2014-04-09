########################################################
# AngularJS service to load in the scope the state of background jobs requested by the user
########################################################

angular.module('feedbunch').service 'jobStateSvc',
['$rootScope', '$http', '$timeout', 'feedsFoldersSvc', 'timerFlagSvc', 'findSvc',
($rootScope, $http, $timeout, feedsFoldersSvc, timerFlagSvc, findSvc)->

  #---------------------------------------------
  # PRIVATE FUNCTION: load list of refresh feed job states via AJAX
  #---------------------------------------------
  load_refresh_feed_job_states = ->
    now = new Date()
    $http.get("/api/refresh_feed_job_states.json?time=#{now.getTime()}")
    .success (data)->
      $rootScope.refresh_feed_job_states = data.slice()
      for job_state in data
        # Periodically update the state of any running jobs
        load_refresh_feed_job_state job_state.id if job_state.state=="RUNNING"
    .error (data, state)->
      # if HTTP call has been prematurely cancelled or there's simply no job states, do nothing
      timerFlagSvc.start 'error_loading_job_states' if state!=0 && state!=404

  #---------------------------------------------
  # PRIVATE FUNCTION: load state of a single refresh feed job via AJAX.
  #
  # Receives as argument the id of the job.
  #---------------------------------------------
  load_refresh_feed_job_state = (job_id)->
    # Store running timers in a hash in the root scope
    $rootScope.refresh_job_state_timers ||= {}

    # Only start a timer to refresh the job state if there isn't a timer already refreshing that job state
    timer = $rootScope.refresh_job_state_timers[job_id]
    if !timer?
      timer = $timeout ->
        # Remove this timer from the list so that another update can be scheduled for 5 seconds in the future
        delete $rootScope.refresh_job_state_timers[job_id]
        now = new Date()
        $http.get("/api/refresh_feed_job_states/#{job_id}.json?time=#{now.getTime()}")
        .success (data)->
          # Update the current state of the job in the root scope
          job = findSvc.find_refresh_feed_job job_id
          job.state = data.state if job?
          if data.state=="RUNNING"
          # If job is running, keep periodically updating its state
            load_refresh_feed_job_state job_id
          else if data.state=="ERROR"
            timerFlagSvc.start 'error_refreshing_feed'
          else if data.state=="SUCCESS"
            timerFlagSvc.start 'success_refresh_feed'
            feedsFoldersSvc.load_feed job.feed_id
        .error (data, state)->
          # if HTTP call has been prematurely cancelled, do nothing
          timerFlagSvc.start 'error_loading_job_states' if state!=0 && state!=404
      , 5000
      # Store timer so that a second timer for the same job state is not started in the future
      $rootScope.refresh_job_state_timers[job_id] = timer

  #---------------------------------------------
  # PRIVATE FUNCTION: load list of subscribe job states via AJAX
  #---------------------------------------------
  load_subscribe_job_states = ->
    now = new Date()
    $http.get("/api/subscribe_job_states.json?time=#{now.getTime()}")
    .success (data)->
      $rootScope.subscribe_job_states = data.slice()
      for job_state in data
        # Periodically update the state of any running jobs
        load_subscribe_job_state job_state.id if job_state.state=="RUNNING"
    .error (data, state)->
      # if HTTP call has been prematurely cancelled or there's simply no job states, do nothing
      timerFlagSvc.start 'error_loading_job_states' if state!=0 && state!=404

  #---------------------------------------------
  # PRIVATE FUNCTION: load state of a single subscribe job via AJAX.
  #
  # Receives as argument the id of the job.
  #---------------------------------------------
  load_subscribe_job_state = (job_id)->
    # Store running timers in a hash in the root scope
    $rootScope.subscribe_job_state_timers ||= {}

    # Only start a timer to refresh the job state if there isn't a timer already refreshing that job state
    timer = $rootScope.subscribe_job_state_timers[job_id]
    if !timer?
      timer = $timeout ->
        # Remove this timer from the list so that another update can be scheduled for 5 seconds in the future
        delete $rootScope.subscribe_job_state_timers[job_id]
        now = new Date()
        $http.get("/api/subscribe_job_states/#{job_id}.json?time=#{now.getTime()}")
        .success (data)->
          # Update the current state of the job in the root scope
          job = findSvc.find_subscribe_job job_id
          job.state = data.state if job?
          if data.state=="RUNNING"
            # If job is running, keep periodically updating its state
            load_subscribe_job_state job_id
          else if data.state=="ERROR"
            timerFlagSvc.start 'error_subscribing'
          else if data.state=="SUCCESS"
            timerFlagSvc.start 'success_subscribe'
            #feedsFoldersSvc.load_feed job.feed_id
        .error (data, state)->
          # if HTTP call has been prematurely cancelled, do nothing
          timerFlagSvc.start 'error_subscribing' if state!=0 && state!=404
      , 5000
      # Store timer so that a second timer for the same job state is not started in the future
      $rootScope.subscribe_job_state_timers[job_id] = timer

  service =

    #---------------------------------------------
    # Load import process state via AJAX into the root scope
    #---------------------------------------------
    load_data: ->
      load_refresh_feed_job_states()
      load_subscribe_job_states()

    #---------------------------------------------
    # Hide a refresh feed job state alert and notify the server via AJAX that it should be deleted
    # from the database (it will not appear again).
    #---------------------------------------------
    hide_refresh_job_alert: (job_state)->
      # Remove job state from scope
      job_state = findSvc.find_refresh_feed_job job_state.id
      if job_state?
        index = $rootScope.refresh_feed_job_states.indexOf job_state
        $rootScope.refresh_feed_job_states.splice index, 1 if index != -1

      # If there is a timer updating this job state, stop it.
      if $rootScope.refresh_job_state_timers?
        timer = $rootScope.refresh_job_state_timers[job_state.id]
        if timer?
          $timeout.cancel timer
          delete $rootScope.refresh_job_state_timers[job_state.id]

      $http.delete "/api/refresh_feed_job_states/#{job_state.id}.json"

    #---------------------------------------------
    # Hide a subscribe job state alert and notify the server via AJAX that it should be deleted
    # from the database (it will not appear again).
    #---------------------------------------------
    hide_subscribe_job_alert: (job_state)->
      # Remove job state from scope
      job_state = findSvc.find_subscribe_job job_state.id
      if job_state?
        index = $rootScope.subscribe_job_states.indexOf job_state
        $rootScope.subscribe_job_states.splice index, 1 if index != -1

      # If there is a timer updating this job state, stop it.
      if $rootScope.subscribe_job_state_timers?
        timer = $rootScope.subscribe_job_state_timers[job_state.id]
        if timer?
          $timeout.cancel timer
          delete $rootScope.subscribe_job_state_timers[job_state.id]

      $http.delete "/api/subscribe_job_states/#{job_state.id}.json"

  return service
]