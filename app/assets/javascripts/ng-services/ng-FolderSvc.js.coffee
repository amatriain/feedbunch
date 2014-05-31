########################################################
# AngularJS service to manage folders
########################################################

angular.module('feedbunch').service 'folderSvc',
['$rootScope', '$http', 'currentFeedSvc', 'currentFolderSvc', 'timerFlagSvc', 'openFolderSvc',
'feedsFoldersSvc', 'unreadCountSvc', 'findSvc',
($rootScope, $http, currentFeedSvc, currentFolderSvc, timerFlagSvc, openFolderSvc,
feedsFoldersSvc, unreadCountSvc, findSvc)->

  #--------------------------------------------
  # Remove a feed from a folder
  #--------------------------------------------
  remove_from_folder: ->
    current_feed = currentFeedSvc.get()
    if current_feed
      current_feed.folder_id = 'none'

      $http.put('/api/folders/none.json', folder: {feed_id: current_feed.id})
      .success (data)->
        feedsFoldersSvc.load_folders()
      .error (data, status)->
        timerFlagSvc.start 'error_managing_folders' if status!=0

  #--------------------------------------------
  # Move a feed to an already existing folder
  #--------------------------------------------
  move_to_folder: (folder)->
    current_feed = currentFeedSvc.get()
    if current_feed
      current_feed.folder_id = folder.id
      # open the new folder
      openFolderSvc.set folder

      $http.put("/api/folders/#{folder.id}.json", folder: {feed_id: current_feed.id})
      .success (data)->
        feedsFoldersSvc.load_folders()
      .error (data, status)->
        timerFlagSvc.start 'error_managing_folders' if status!=0

  #--------------------------------------------
  # Move a feed to a new folder
  #--------------------------------------------

  move_to_new_folder: (title)->
    current_feed = currentFeedSvc.get()
    if title && current_feed
      $http.post("/api/folders.json", folder: {feed_id: current_feed.id, title: title})
      .success (data)->
        feedsFoldersSvc.add_folder data
        current_feed.folder_id = data.id
        feedsFoldersSvc.load_folders()

        # open the new folder
        openFolderSvc.set data
      .error (data, status)->
        if status == 304
          timerFlagSvc.start 'error_already_existing_folder'
        else if status!=0
          timerFlagSvc.start 'error_creating_folder'

  #--------------------------------------------
  # Function to filter folders which should be visible. Returns a function that returns true if
  # the folder should be visible, false otherwise.
  #--------------------------------------------
  show_folder_filter: (folder)->
    return (folder)->
      # If "show_read" flag is set to true, always show all folders
      if $rootScope.show_read
        return true

      # Always show the currently selected folder, or the folder of the currently selected feed
      current_feed = currentFeedSvc.get()
      current_folder = currentFolderSvc.get()
      if current_feed?.folder_id == folder.id || current_folder?.id == folder.id
        return true

      # Always show a folder if any of its feeds has a job state alert in the start page
      feeds = findSvc.find_folder_feeds folder
      if feeds?.length > 0
        for feed in feeds
          subscribeJobStates = findSvc.find_feed_subscribe_jobs feed.id
          return true if subscribeJobStates?.length > 0
          refreshFeedJobStates = findSvc.find_feed_refresh_jobs feed.id
          return true if refreshFeedJobStates?.length > 0

      # If the folder is not in any of the above cases, show it only if it has unread entries
      return unreadCountSvc.folder_unread_entries(folder) > 0
]