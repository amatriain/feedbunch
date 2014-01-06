########################################################
# AngularJS service to manage unread entries counts
########################################################

angular.module('feedbunch').service 'unreadCountSvc',
['$rootScope', 'findSvc',
($rootScope, findSvc)->

  #--------------------------------------------
  # Count the number of unread entries in a folder
  #--------------------------------------------
  folder_unread_entries: (folder)->
    sum = 0
    feeds = findSvc.find_folder_feeds folder
    if feeds && feeds?.length > 0
      for feed in feeds
        sum += feed.unread_entries
    return sum

  #--------------------------------------------
  # Count the total number of unread entries in feeds
  #--------------------------------------------
  total_unread_entries: ->
    sum = 0
    if $rootScope.feeds && $rootScope.feeds?.length > 0
      for feed in $rootScope.feeds
        sum += feed.unread_entries
    return sum
]