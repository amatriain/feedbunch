########################################################
# AngularJS service to manage folders
########################################################

angular.module('feedbunch').service 'folderSvc',
['$rootScope', '$http', 'findSvc', 'currentFeedSvc', 'timerFlagSvc', 'openFolderSvc', 'feedsFoldersSvc',
($rootScope, $http, findSvc, currentFeedSvc, timerFlagSvc, openFolderSvc, feedsFoldersSvc)->

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

  service =

    #--------------------------------------------
    # Remove a feed from a folder
    #--------------------------------------------
    remove_from_folder: ->
      folder_id = currentFeedSvc.get().folder_id
      currentFeedSvc.get().folder_id = 'none'
      feed_removed currentFeedSvc.get(), folder_id

      # open the "all subscriptions" folder
      folder_all = findSvc.find_folder 'all'
      openFolderSvc.open folder_all

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

      # open the new folder
      openFolderSvc.open folder

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
          feedsFoldersSvc.add_folder data
          old_folder_id = currentFeedSvc.get().folder_id
          currentFeedSvc.get().folder_id = data.id
          feed_removed currentFeedSvc.get(), old_folder_id

          # open the new folder
          openFolderSvc.open data
        .error (data, status)->
          if status == 304
            timerFlagSvc.start 'error_already_existing_folder'
          else
            timerFlagSvc.start 'error_creating_folder'

  return service
]