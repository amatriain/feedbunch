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
      # Remove any refresh_feed_job_state associated with the feed
      refresh_job_states = findSvc.find_feed_refresh_jobs feed_id
      if refresh_job_states?
        for job_state in refresh_job_states
          index_job_state = $rootScope.refresh_feed_job_states.indexOf job_state
          $rootScope.refresh_feed_job_states.splice index_job_state, 1 if index_job_state != -1

      # Remove any subscribe_job_state associated with the feed
      subscribe_job_states = findSvc.find_feed_subscribe_jobs feed_id
      if subscribe_job_states?
        for job_state in subscribe_job_states
          index_job_state = $rootScope.subscribe_job_states.indexOf job_state
          $rootScope.subscribe_job_states.splice index_job_state, 1 if index_job_state != -1

      # Remove the feed
      feed = findSvc.find_feed feed_id
      # Delete feed model from the scope
      index_feed = $rootScope.feeds.indexOf feed
      $rootScope.feeds.splice index_feed, 1 if index_feed != -1

  #---------------------------------------------
  # Remove a folder from the folders array.
  #---------------------------------------------
  remove_folder: (folder_id)->
    if $rootScope.folders
      folder = findSvc.find_folder folder_id
      # Delete folder model from the scope
      index = $rootScope.folders.indexOf folder
      $rootScope.folders.splice index, 1 if index != -1

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

        # Feeds without unread entries with a refresh feed alert in the start page are not removed
        refresh_job_states = findSvc.find_feed_refresh_jobs feed.id
        return false if refresh_job_states? && refresh_job_states?.length > 0

        # Feeds without unread entries with a subscribe alert in the start page are not removed
        subscribe_job_states = findSvc.find_feed_subscribe_jobs feed.id
        return false if subscribe_job_states? && subscribe_job_states?.length > 0

        # The rest of feeds are removed
        return true

      if read_feeds? && read_feeds?.length > 0
        for feed in read_feeds
          # The current feed, or feeds in the current folder, are not removed
          if $rootScope.current_feed?.id != feed.id && $rootScope.current_folder?.id != feed.folder_id
            # Delete feed from the scope
            index = $rootScope.feeds.indexOf feed
            $rootScope.feeds.splice index, 1 if index != -1

]