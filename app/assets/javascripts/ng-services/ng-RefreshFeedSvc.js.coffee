########################################################
# AngularJS service to refresh feeds
########################################################

angular.module('feedbunch').service 'refreshFeedSvc',
['$rootScope', '$http', 'timerFlagSvc', 'entriesPaginationSvc', 'startPageSvc',
($rootScope, $http, timerFlagSvc, entriesPaginationSvc, startPageSvc)->

  service =

    #--------------------------------------------
    # Refresh a feed and load its unread entries
    #--------------------------------------------
    refresh_feed: ->
      entriesPaginationSvc.reset_entries()
      entriesPaginationSvc.set_busy true

      $http.put("/api/feeds/#{$rootScope.current_feed.id}.json")
      .success (data)->
        startPageSvc.show_start_page()
      .error (data, status)->
        startPageSvc.show_start_page()
        timerFlagSvc.start 'error_refreshing_feed' if status!=0

  return service
]
