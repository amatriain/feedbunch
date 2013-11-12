########################################################
# AngularJS service to manage subscribing and unsubscribing from feeds
########################################################

angular.module('feedbunch').service 'subscriptionSvc',
['$rootScope', '$http', 'currentFeedSvc', 'currentFolderSvc', 'readSvc', 'folderSvc', 'timerFlagSvc',
'entriesPaginationSvc', 'openFolderSvc', 'feedsFoldersSvc', 'cleanupSvc',
($rootScope, $http, currentFeedSvc, currentFolderSvc, readSvc, folderSvc, timerFlagSvc,
entriesPaginationSvc, openFolderSvc, feedsFoldersSvc, cleanupSvc)->

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
        entriesPaginationSvc.set_busy false
        feedsFoldersSvc.add_feed data
        currentFeedSvc.set data
        readSvc.read_entries_page()
      .error (data, status)->
        entriesPaginationSvc.set_busy false
        # Show alert
        if status == 304
          timerFlagSvc.start 'error_already_subscribed'
        else
          timerFlagSvc.start 'error_subscribing'

  unsubscribe: ->
    current_feed = currentFeedSvc.get()
    if current_feed
      # Before deleting from the global scope, save some data we'll need later
      path = "/feeds/#{current_feed.id}.json"

      # Remove feed from feeds list
      cleanupSvc.remove_feed current_feed.id

      # Tell the model that no feed is currently selected.
      currentFeedSvc.unset()

      $http.delete(path)
      .error ->
        timerFlagSvc.start 'error_unsubscribing'

]