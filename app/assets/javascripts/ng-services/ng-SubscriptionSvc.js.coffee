########################################################
# AngularJS service to manage subscribing and unsubscribing from feeds
########################################################

angular.module('feedbunch').service 'subscriptionSvc',
['$rootScope', '$http', 'currentFeedSvc', 'readSvc', 'findSvc',
($rootScope, $http, currentFeedSvc, readSvc, findSvc)->

  #---------------------------------------------
  # Add a subscription to a feed
  #---------------------------------------------
  subscribe: (url)->
    # Feed URL
    if url
      currentFeedSvc.unset()
      $rootScope.loading_entries = true

      $http.post('/feeds.json', feed:{url: url})
      .success (data)->
        $rootScope.loading_entries = false
        $rootScope.feeds.push data
        readSvc.read_feed data
        findSvc.find_folder('all').unread_entries += data.unread_entries
      .error (data, status)->
        $rootScope.loading_entries = false
        # Show alert
        if status == 304
          timerFlagSvc.start 'error_already_subscribed'
        else
          timerFlagSvc.start 'error_subscribing'

]