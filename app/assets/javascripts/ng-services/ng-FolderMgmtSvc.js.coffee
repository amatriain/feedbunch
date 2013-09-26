########################################################
# AngularJS service to manage subscribing and unsubscribing from feeds
########################################################

angular.module('feedbunch').service 'folderMgmtSvc',
['$rootScope', '$http', 'findSvc', 'currentFeedSvc',
($rootScope, $http, findSvc, currentFeedSvc)->

  #--------------------------------------------
  # PRIVATE FUNCTION: Update the model to account for a feed having been removed from a folder
  #--------------------------------------------
  feed_removed = (feed, folder_id)->
    folder = findSvc.find_folder folder_id
    if folder != null
      # Remove folder if it's empty
      if findSvc.find_folder_feeds(folder_id).length == 0
        index = $rootScope.folders.indexOf folder
        $rootScope.folders.splice index, 1 if index != -1
        # Otherwise update unread entries in folder
      else
        folder.unread_entries -= feed.unread_entries

  #--------------------------------------------
  # Remove a feed from a folder
  #--------------------------------------------
  remove_from_folder: ->
    folder_id = currentFeedSvc.get().folder_id
    currentFeedSvc.get().folder_id = 'none'
    feed_removed currentFeedSvc.get(), folder_id

    $http.put('/folders/none.json', folder: {feed_id: currentFeedSvc.get().id})
    .error ->
      timerFlagSvc.start 'error_managing_folders'

  #--------------------------------------------
  # Update the model to account for a feed having been removed from a folder
  #--------------------------------------------
  feed_removed_from_folder: feed_removed

  #--------------------------------------------
  # Move a feed to an already existing folder
  #--------------------------------------------
  move_to_folder: (folder)->
    old_folder_id = currentFeedSvc.get().folder_id
    currentFeedSvc.get().folder_id = folder.id
    feed_removed currentFeedSvc.get(), old_folder_id
    folder.unread_entries += currentFeedSvc.get().unread_entries

    $http.put("/folders/#{folder.id}.json", folder: {feed_id: currentFeedSvc.get().id})
    .error ->
      timerFlagSvc.start 'error_managing_folders'

  #--------------------------------------------
  # Move a feed to a new folder
  #--------------------------------------------

  move_to_new_folder: (title)->
    if title
      $http.post("/folders.json", folder: {feed_id: currentFeedSvc.get().id, title: title})
      .success (data)->
        $rootScope.folders.push data
        old_folder_id = currentFeedSvc.get().folder_id
        currentFeedSvc.get().folder_id = data.id
        feed_removed currentFeedSvc.get(), old_folder_id
      .error (data, status)->
        if status == 304
          timerFlagSvc.start 'error_already_existing_folder'
        else
          timerFlagSvc.start 'error_creating_folder'
]