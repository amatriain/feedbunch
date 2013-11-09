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
    else if id == "all"
      return {id: "all"}
    else
      folders = $filter('filter') $rootScope.folders, {id: id}
      return folders[0]

  #---------------------------------------------
  # Find feeds in a folder given the folder
  #---------------------------------------------
  find_folder_feeds: (folder)->
    if folder != 'all'
      return $filter('filter') $rootScope.feeds, (feed)->
        return feed.folder_id == folder.id
    else
      return $rootScope.feeds
]