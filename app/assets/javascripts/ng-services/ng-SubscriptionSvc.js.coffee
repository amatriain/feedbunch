########################################################
# AngularJS service to manage subscribing and unsubscribing from feeds
########################################################

angular.module('feedbunch').service 'subscriptionSvc',
['$rootScope', '$http', '$window', 'currentFeedSvc', 'currentFolderSvc', 'readSvc', 'folderSvc', 'timerFlagSvc',
'entriesPaginationSvc', 'openFolderSvc', 'feedsFoldersSvc', 'cleanupSvc', 'favicoSvc',
($rootScope, $http, $window, currentFeedSvc, currentFolderSvc, readSvc, folderSvc, timerFlagSvc,
entriesPaginationSvc, openFolderSvc, feedsFoldersSvc, cleanupSvc, favicoSvc)->

  #---------------------------------------------
  # Add a subscription to a feed
  #---------------------------------------------
  subscribe: (url)->
    # Feed URL
    if url
      currentFeedSvc.unset()
      currentFolderSvc.unset()
      entriesPaginationSvc.set_busy true

      $http.post('/feeds.json', feed:{url: url})
      .success (data)->
        $rootScope.subscribed_feeds_count += 1
        entriesPaginationSvc.set_busy false
        feedsFoldersSvc.add_feed data
        favicoSvc.update_unread_badge()
        currentFeedSvc.set data
        readSvc.read_entries_page()
      .error (data, status)->
        entriesPaginationSvc.set_busy false
        if status == 401
          $window.location.href = '/login'
        # Show alert
        else if status == 304
          timerFlagSvc.start 'error_already_subscribed'
        else if status!=0
          timerFlagSvc.start 'error_subscribing'

  unsubscribe: ->
    current_feed = currentFeedSvc.get()
    if current_feed
      # Before deleting from the global scope, save some data we'll need later
      path = "/feeds/#{current_feed.id}.json"

      # Remove feed from feeds list
      cleanupSvc.remove_feed current_feed.id
      favicoSvc.update_unread_badge()

      # Tell the model that no feed is currently selected.
      currentFeedSvc.unset()

      $http.delete(path)
      .success ->
        $rootScope.subscribed_feeds_count -= 1
        # In case the folder has been deleted after unsubscribing from a feed (because there are no more feeds in the folder),
        # reload folders from the server.
        feedsFoldersSvc.load_folders()
      .error (data, status)->
        if status == 401
          $window.location.href = '/login'
        else if status!=0
          timerFlagSvc.start 'error_unsubscribing'

]