########################################################
# AngularJS service to manage subscribing and unsubscribing from feeds
########################################################

angular.module('feedbunch').service 'subscriptionSvc',
['$rootScope', '$http', 'currentFeedSvc', 'currentFolderSvc', 'readSvc', 'findSvc', 'folderSvc', 'timerFlagSvc',
'scrollSvc', 'entriesPaginationSvc', 'openFolderSvc', 'feedsFoldersSvc',
($rootScope, $http, currentFeedSvc, currentFolderSvc, readSvc, findSvc, folderSvc, timerFlagSvc,
scrollSvc, entriesPaginationSvc, openFolderSvc, feedsFoldersSvc)->

  #---------------------------------------------
  # Add a subscription to a feed
  #---------------------------------------------
  subscribe: (url)->
    # Feed URL
    if url
      currentFeedSvc.unset()
      currentFolderSvc.unset()
      entriesPaginationSvc.set_busy true
      scrollSvc.scroll_top()

      $http.post('/feeds.json', feed:{url: url})
      .success (data)->
        entriesPaginationSvc.set_busy false
        feedsFoldersSvc.add_feed data
        currentFeedSvc.set data
        readSvc.read_entries_page()

        # open the "all subscriptions" folder
        folder_all = findSvc.find_folder 'all'
        openFolderSvc.open folder_all
      .error (data, status)->
        entriesPaginationSvc.set_busy false
        # Show alert
        if status == 304
          timerFlagSvc.start 'error_already_subscribed'
        else
          timerFlagSvc.start 'error_subscribing'

  unsubscribe: ->
    # Delete feed model from the scope
    index = $rootScope.feeds.indexOf currentFeedSvc.get()
    $rootScope.feeds.splice index, 1 if index != -1

    # Before deleting from the global scope, save some data we'll need later
    path = "/feeds/#{currentFeedSvc.get().id}.json"
    folder_id = currentFeedSvc.get().folder_id

    # Update folders
    folderSvc.feed_removed_from_folder currentFeedSvc.get(), folder_id

    # Tell the model that no feed is currently selected.
    currentFeedSvc.unset()

    # Close all folders, indicate no folder is open
    openFolderSvc.close_all()

    scrollSvc.scroll_top()

    $http.delete(path)
    .error ->
      timerFlagSvc.start 'error_unsubscribing'

]