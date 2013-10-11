########################################################
# AngularJS service to find objects in the root scope
########################################################

angular.module('feedbunch').service 'findSvc',
['$rootScope', '$filter', ($rootScope, $filter)->

  #---------------------------------------------
  # Find a feed given its id
  #---------------------------------------------
  find_feed: (id)->
    feeds = $filter('filter') $rootScope.feeds, {id: id}
    return feeds[0]

  #---------------------------------------------
  # Find a folder given its id
  #---------------------------------------------
  find_folder: (id)->
    if id == 'none'
      return null
    else
      folders = $filter('filter') $rootScope.folders, {id: id}
      return folders[0]

  #---------------------------------------------
  # Find feeds in a folder given the folder id
  #---------------------------------------------
  find_folder_feeds: (folder_id)->
    if folder_id != 'all'
      return $filter('filter') $rootScope.feeds, {folder_id: folder_id}
    else
      return $rootScope.feeds
]