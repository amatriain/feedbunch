########################################################
# AngularJS service to find objects in the root scope
########################################################

angular.module('feedbunch').service 'findSvc',
['$rootScope', '$filter', ($rootScope, $filter)->

  #---------------------------------------------
  # Find a feed given its id.
  # If a list of feeds is passed, search in the list. Otherwise, search in the list
  # of feeds stored in the root scope.
  #---------------------------------------------
  find_feed: (id, list = $rootScope.feeds)->
    if list
      feeds = $filter('filter') list, (feed)->
        return feed.id == id
      if feeds?.length > 0
        return feeds[0]
      else
        return null
    else
      return null

  #---------------------------------------------
  # Find a folder given its id.
  # If a list of folders is passed, search in the list. Otherwise, search in the list
  # of folders stored in the root scope
  #---------------------------------------------
  find_folder: (id, list = $rootScope.folders)->
    if list
      if id == 'none'
        return null
      else if id == "all"
        return {id: "all"}
      else
        folders = $filter('filter') list, (folder)->
          return folder.id == id
        if folders?.length > 0
          return folders[0]
        else
          return null
    else
      return null

  #---------------------------------------------
  # Find feeds in a folder given the folder
  #---------------------------------------------
  find_folder_feeds: (folder)->
    if $rootScope.feeds
      if folder != 'all' && folder.id != 'all'
        feeds =  $filter('filter') $rootScope.feeds, (feed)->
          return feed.folder_id == folder.id
        if feeds?.length > 0
          return feeds
        else
          return null
      else
        return $rootScope.feeds
    else
      return null

  #---------------------------------------------
  # Find entries in a feed given the feed
  #---------------------------------------------
  find_feed_entries: (feed)->
    if $rootScope.entries
      entries =  $filter('filter') $rootScope.entries, (entry)->
        return entry.feed_id == feed.id
      if entries?.length > 0
        return entries
      else
        return null
    else
      return null

  #---------------------------------------------
  # Find an entry given its id
  #---------------------------------------------
  find_entry: (id)->
    if $rootScope.entries
      entries = $filter('filter') $rootScope.entries, (entry)->
        return entry.id == id
      if entries?.length > 0
        return entries[0]
      else
        return null
    else
      return null

  #---------------------------------------------
  # Find a refresh feed job state object given its id
  #---------------------------------------------
  find_refresh_feed_job: (id)->
    if $rootScope.refresh_feed_job_states
      job_states = $filter('filter') $rootScope.refresh_feed_job_states, (job_state)->
        return job_state.id == id
      if job_states?.length > 0
        return job_states[0]
      else
        return null
    else
      return null

  #---------------------------------------------
  # Find all refresh feed job state objects associated with a feed, given its id
  #---------------------------------------------
  find_feed_refresh_jobs: (id)->
    if $rootScope.refresh_feed_job_states
      job_states = $filter('filter') $rootScope.refresh_feed_job_states, (job_state)->
        return job_state.feed_id == id
      return job_states
    else
      return null

  #---------------------------------------------
  # Find all subscribe job state objects associated with a feed, given its id
  #---------------------------------------------
  find_feed_subscribe_jobs: (id)->
    if $rootScope.subscribe_job_states
      job_states = $filter('filter') $rootScope.subscribe_job_states, (job_state)->
        return job_state.feed_id == id
      return job_states
    else
      return null

  #---------------------------------------------
  # Find a subscribe job state object given its id
  #---------------------------------------------
  find_subscribe_job: (id)->
    if $rootScope.subscribe_job_states
      job_states = $filter('filter') $rootScope.subscribe_job_states, (job_state)->
        return job_state.id == id
      if job_states?.length > 0
        return job_states[0]
      else
        return null
    else
      return null
]