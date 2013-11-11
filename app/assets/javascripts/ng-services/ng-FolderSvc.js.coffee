########################################################
# AngularJS service to manage folders
########################################################

angular.module('feedbunch').service 'folderSvc',
['$rootScope', '$http', 'currentFeedSvc', 'timerFlagSvc', 'openFolderSvc', 'feedsFoldersSvc',
($rootScope, $http, currentFeedSvc, timerFlagSvc, openFolderSvc, feedsFoldersSvc)->

  #--------------------------------------------
  # Remove a feed from a folder
  #--------------------------------------------
  remove_from_folder: ->
    current_feed = currentFeedSvc.get()
    if current_feed
      current_feed.folder_id = 'none'

      $http.put('/folders/none.json', folder: {feed_id: current_feed.id})
      .success (data)->
        feedsFoldersSvc.load_folders()
      .error ->
        timerFlagSvc.start 'error_managing_folders'

  #--------------------------------------------
  # Move a feed to an already existing folder
  #--------------------------------------------
  move_to_folder: (folder)->
    current_feed = currentFeedSvc.get()
    if current_feed
      current_feed.folder_id = folder.id
      # open the new folder
      openFolderSvc.set folder

      $http.put("/folders/#{folder.id}.json", folder: {feed_id: current_feed.id})
      .success (data)->
        feedsFoldersSvc.load_folders()
      .error ->
        timerFlagSvc.start 'error_managing_folders'

  #--------------------------------------------
  # Move a feed to a new folder
  #--------------------------------------------

  move_to_new_folder: (title)->
    current_feed = currentFeedSvc.get()
    if title && current_feed
      $http.post("/folders.json", folder: {feed_id: current_feed.id, title: title})
      .success (data)->
        feedsFoldersSvc.add_folder data
        current_feed.folder_id = data.id
        feedsFoldersSvc.load_folders()

        # open the new folder
        openFolderSvc.set data
      .error (data, status)->
        if status == 304
          timerFlagSvc.start 'error_already_existing_folder'
        else
          timerFlagSvc.start 'error_creating_folder'
]