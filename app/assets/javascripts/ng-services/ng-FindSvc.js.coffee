########################################################
# AngularJS service to find objects in the root scope
########################################################

angular.module('feedbunch').service 'findSvc',
['$rootScope', '$filter', ($rootScope, $filter)->

  #---------------------------------------------
  # Find a feed given its id
  #---------------------------------------------
  find_feed: (id)->
    if $rootScope.feeds
      feeds = $filter('filter') $rootScope.feeds, (feed)->
        return feed.id == id
      if feeds?.length > 0
        return feeds[0]
      else
        return null
    else
      return null

  #---------------------------------------------
  # Find a folder given its id
  #---------------------------------------------
  find_folder: (id)->
    if $rootScope.folders
      if id == 'none'
        return null
      else if id == "all"
        return {id: "all"}
      else
        folders = $filter('filter') $rootScope.folders, (folder)->
          return folder.id == id
        if folders?.length > 0
          return folders[0]
        else
          return null
    else
      return null

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