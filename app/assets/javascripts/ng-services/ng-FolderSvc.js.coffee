########################################################
# AngularJS service to manage folders
########################################################

angular.module('feedbunch').service 'folderSvc',
['$rootScope', '$http', 'findSvc', 'currentFeedSvc', 'timerFlagSvc', 'openFolderSvc', 'feedsFoldersSvc',
($rootScope, $http, findSvc, currentFeedSvc, timerFlagSvc, openFolderSvc, feedsFoldersSvc)->

  #--------------------------------------------
  # Remove a feed from a folder
  #--------------------------------------------
  remove_from_folder: ->
    folder_id = currentFeedSvc.get().folder_id
    currentFeedSvc.get().folder_id = 'none'
    feedsFoldersSvc.feed_removed_from_folder folder_id

    # open the "all subscriptions" folder
    folder_all = findSvc.find_folder 'all'
    openFolderSvc.open folder_all

    $http.put('/folders/none.json', folder: {feed_id: currentFeedSvc.get().id})
    .error ->
      timerFlagSvc.start 'error_managing_folders'

  #--------------------------------------------
  # Move a feed to an already existing folder
  #--------------------------------------------
  move_to_folder: (folder)->
    old_folder_id = currentFeedSvc.get().folder_id
    currentFeedSvc.get().folder_id = folder.id
    feedsFoldersSvc.feed_removed_from_folder old_folder_id

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
        feedsFoldersSvc.feed_removed_from_folder old_folder_id

        # open the new folder
        openFolderSvc.open data
      .error (data, status)->
        if status == 304
          timerFlagSvc.start 'error_already_existing_folder'
        else
          timerFlagSvc.start 'error_creating_folder'
]