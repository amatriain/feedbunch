########################################################
# AngularJS service to keep track of the state of pagination of feeds
########################################################

angular.module('feedbunch').service 'feedsPaginationSvc',
['$rootScope', 'findSvc', ($rootScope, findSvc)->

  #--------------------------------------------
  # PRIVATE FUNCTION: mark all entries as unrefreshed in the current refresh cycle.
  #--------------------------------------------
  mark_all_unrefreshed = ->
    if $rootScope.feeds?
      for feed in $rootScope.feeds
        feed.refreshed = false

  #--------------------------------------------
  # PRIVATE FUNCTION: mark all entries as refreshed in the current refresh cycle.
  #--------------------------------------------
  mark_all_refreshed = ->
    if $rootScope.feeds?
      for feed in $rootScope.feeds
        feed.refreshed = true

  service =

    #---------------------------------------------
    # Get the AJAX call state: if busy, return true; otherwise return false
    #---------------------------------------------
    is_busy: ->
      return $rootScope.loading_feeds_busy

    #---------------------------------------------
    # Set the AJAX call state: true if busy, false otherwise
    #---------------------------------------------
    set_busy: (busy) ->
      $rootScope.loading_feeds_busy = busy

    #---------------------------------------------
    # Load a page of feeds retrieved from the server into the root scope.
    # Receives as arguments the page number and the array of feeds.
    #---------------------------------------------
    load_feeds_page: (page, feeds)->
      # Mark all feeds as unrefreshed at the start of the refresh cycle
      mark_all_unrefreshed() if page == 1

      if !$rootScope.feeds || $rootScope.feeds?.length==0
        # If there are no feeds in scope, just store the feeds returned.
        $rootScope.feeds = feeds
        mark_all_refreshed()
      else
        # Update unread counts of passed feeds, insert any new ones not yet in the root scope
        for feed_new in feeds
          feed_old = findSvc.find_feed feed_new.id
          if feed_old?
            feed_old.unread_entries = feed_new.unread_entries
            feed_old.refreshed = true
          else
            $rootScope.feeds.push feed_new
            feed_new.refreshed = true

    #---------------------------------------------
    # Set to zero the unread count of feeds not received from the server.
    #---------------------------------------------
    pagination_finished: ->
      # Set to zero the unread count of feeds that have not been refreshed during the refresh cycle
      # (this means those feeds are in the root scope but have not been returned by the server, which means
      # their unread count is zero if only unread feeds are being retrieved)
      if $rootScope.feeds && $rootScope.feeds?.length>0
        for feed in $rootScope.feeds
          feed.unread_entries = 0 if !feed.refreshed

  return service
]