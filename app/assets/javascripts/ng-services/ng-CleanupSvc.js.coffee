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

  #--------------------------------------------
  # Remove feeds without unread entries from the root scope, unless the user has
  # selected to display all feeds including read ones.
  #
  # Feeds that have a job status alert in the start page are not removed.
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
          job_statuses = $filter('filter') $rootScope.refresh_feed_job_statuses, (job_status)->
            # Find refresh_feed_job_statuses for this feed
            return job_status.feed_id == feed.id
          if job_statuses? && job_statuses?.length > 0
            # Feeds with a job status are not removed
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