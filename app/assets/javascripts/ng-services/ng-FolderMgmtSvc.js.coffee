########################################################
# AngularJS service to manage subscribing and unsubscribing from feeds
########################################################

angular.module('feedbunch').service 'folderMgmtSvc',
['$rootScope', 'findSvc', ($rootScope, findSvc)->

  #--------------------------------------------
  # Update the model to account for a feed having been removed from a folder
  #--------------------------------------------
  feed_removed_from_folder: (feed, folder_id)->
    folder = findSvc.find_folder folder_id
    if folder != null
      # Remove folder if it's empty
      if findSvc.find_folder_feeds(folder_id).length == 0
        index = $rootScope.folders.indexOf folder
        $rootScope.folders.splice index, 1 if index != -1
        # Otherwise update unread entries in folder
      else
        folder.unread_entries -= feed.unread_entries
]