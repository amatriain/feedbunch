########################################################
# AngularJS service to manage subscribing and unsubscribing from feeds
########################################################

angular.module('feedbunch').service 'subscriptionSvc',
['$rootScope', '$http', 'currentFeedSvc', 'currentFolderSvc', 'readSvc', 'findSvc', 'folderSvc', 'timerFlagSvc', 'scrollSvc',
($rootScope, $http, currentFeedSvc, currentFolderSvc, readSvc, findSvc, folderSvc, timerFlagSvc, scrollSvc)->

  #---------------------------------------------
  # Add a subscription to a feed
  #---------------------------------------------
  subscribe: (url)->
    # Feed URL
    if url
      currentFeedSvc.unset()
      currentFolderSvc.unset()
      $rootScope.loading_entries = true
      scrollSvc.scroll_top()

      $http.post('/feeds.json', feed:{url: url})
      .success (data)->
        $rootScope.loading_entries = false
        $rootScope.feeds.push data
        currentFeedSvc.set data
        readSvc.read_entries_page()
        findSvc.find_folder('all').unread_entries += data.unread_entries
      .error (data, status)->
        $rootScope.loading_entries = false
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
    unread_entries = currentFeedSvc.get().unread_entries
    folder_id = currentFeedSvc.get().folder_id

    # Update folders
    findSvc.find_folder('all').unread_entries -= unread_entries
    folderSvc.feed_removed_from_folder currentFeedSvc.get(), folder_id

    # Tell the model that no feed is currently selected.
    currentFeedSvc.unset()

    scrollSvc.scroll_top()

    $http.delete(path)
    .error ->
      timerFlagSvc.start 'error_unsubscribing'

]