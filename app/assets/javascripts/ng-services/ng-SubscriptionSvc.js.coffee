########################################################
# AngularJS service to manage subscribing and unsubscribing from feeds
########################################################

angular.module('feedbunch').service 'subscriptionSvc',
['$rootScope', '$http', 'currentFeedSvc', 'currentFolderSvc', 'readSvc', 'folderSvc', 'timerFlagSvc',
'entriesPaginationSvc', 'openFolderSvc', 'feedsFoldersSvc', 'cleanupSvc', 'favicoSvc', 'startPageSvc',
($rootScope, $http, currentFeedSvc, currentFolderSvc, readSvc, folderSvc, timerFlagSvc,
entriesPaginationSvc, openFolderSvc, feedsFoldersSvc, cleanupSvc, favicoSvc, startPageSvc)->

  #---------------------------------------------
  # Add a subscription to a feed
  #---------------------------------------------
  subscribe: (url)->
    # Feed URL
    if url
      entriesPaginationSvc.reset_entries()
      entriesPaginationSvc.set_busy true

      $http.post('/api/feeds.json', feed:{url: url})
      .success (data)->
        startPageSvc.show_start_page()
      .error (data, status)->
        entriesPaginationSvc.set_busy false
        # Show alert
        timerFlagSvc.start 'error_subscribing'

  unsubscribe: ->
    current_feed = currentFeedSvc.get()
    if current_feed
      # Before deleting from the global scope, save some data we'll need later
      path = "/api/feeds/#{current_feed.id}.json"

      # Remove feed from feeds list
      cleanupSvc.remove_feed current_feed.id
      favicoSvc.update_unread_badge()

      # Reset the timer that updates feeds every minute, to give the server time to
      # actually delete the feed subscription before the next update
      feedsFoldersSvc.reset_refresh_timer()

      # Tell the model that no feed is currently selected.
      currentFeedSvc.unset()

      $http.delete(path)
      .success ->
        $rootScope.subscribed_feeds_count -= 1
        # In case the folder has been deleted after unsubscribing from a feed (because there are no more feeds in the folder),
        # reload folders from the server.
        # TODO this needs rewriting now that unsubscribing happens in a background job instead of immediately
        # feedsFoldersSvc.load_folders()
      .error (data, status)->
        timerFlagSvc.start 'error_unsubscribing' if status!=0

]