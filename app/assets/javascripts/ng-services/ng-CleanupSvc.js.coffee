########################################################
# AngularJS service to remove feeds, and hide read feeds in the view
########################################################

angular.module('feedbunch').service 'cleanupSvc',
['$rootScope', '$filter', 'findSvc',
($rootScope, $filter, findSvc)->

  #---------------------------------------------
  # Remove a feed from the feeds array.
  #---------------------------------------------
  remove_feed: (feed_id)->
    if $rootScope.feeds
      feed = findSvc.find_feed feed_id
      # Delete feed model from the scope
      index = $rootScope.feeds.indexOf feed
      if index != -1
        $rootScope.feeds.splice index, 1

  #---------------------------------------------
  # Remove a folder from the folders array.
  #---------------------------------------------
  remove_folder: (folder_id)->
    if $rootScope.folders
      folder = findSvc.find_folder folder_id
      # Delete folder model from the scope
      index = $rootScope.folders.indexOf folder
      if index != -1
        $rootScope.folders.splice index, 1

  #--------------------------------------------
  # Remove feeds without unread entries from the root scope, unless the user has
  # selected to display all feeds including read ones.
  #
  # Feeds that have a job state alert in the start page are not removed.
  #
  # If the user clicks on the same feed or on its folder, do nothing.
  #--------------------------------------------
  hide_read_feeds: ->
    if $rootScope.feeds && !$rootScope.show_read
      read_feeds = $filter('filter') $rootScope.feeds, (feed)->
        if feed.unread_entries > 0
          # Feeds with unread entries are not removed
          return false
        else
          job_states = $filter('filter') $rootScope.refresh_feed_job_states, (job_state)->
            # Find refresh_feed_job_states for this feed
            return job_state.feed_id == feed.id
          if job_states? && job_states?.length > 0
            # Feeds with a job state are not removed
            return false
          else
            # The rest of feeds are removed
            return true
      if read_feeds? && read_feeds?.length > 0
        for feed in read_feeds
          if $rootScope.current_feed?.id != feed.id && $rootScope.current_folder?.id != feed.folder_id
            # Delete feed from the scope
            index = $rootScope.feeds.indexOf feed
            $rootScope.feeds.splice index, 1 if index != -1

]