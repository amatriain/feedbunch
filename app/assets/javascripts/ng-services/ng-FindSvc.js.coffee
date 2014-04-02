########################################################
# AngularJS service to find objects in the root scope
########################################################

angular.module('feedbunch').service 'findSvc',
['$rootScope', '$filter', ($rootScope, $filter)->

  #---------------------------------------------
  # Find a feed given its id
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
  # Find a folder given its id
  #---------------------------------------------
  find_folder: (id)->
    if $rootScope.folders
      if id == 'none'
        return null
      else if id == "all"
        return {id: "all"}
      else
        folders = $filter('filter') $rootScope.folders, (folder)->
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
      if folder != 'all'
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
  # Find a feed refresh job status object given its id
  #---------------------------------------------
  find_refresh_feed_job: (id)->
    if $rootScope.refresh_feed_job_statuses
      job_statuses = $filter('filter') $rootScope.refresh_feed_job_statuses, (job_status)->
        return job_status.id == id
      if job_statuses?.length > 0
        return job_statuses[0]
      else
        return null
    else
      return null
]