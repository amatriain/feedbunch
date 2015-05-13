########################################################
# AngularJS service to manage subscribing and unsubscribing from feeds
########################################################

angular.module('feedbunch').service 'subscriptionSvc',
['$rootScope', '$http', 'readSvc', 'folderSvc', 'timerFlagSvc',
'entriesPaginationSvc', 'openFolderSvc', 'feedsFoldersSvc', 'cleanupSvc', 'favicoSvc', 'startPageSvc',
($rootScope, $http, readSvc, folderSvc, timerFlagSvc,
entriesPaginationSvc, openFolderSvc, feedsFoldersSvc, cleanupSvc, favicoSvc, startPageSvc)->

  #---------------------------------------------
  # Add a subscription to a feed
  #---------------------------------------------
  subscribe: (url)->
    # Feed URL
    if url
      entriesPaginationSvc.reset_entries()
      entriesPaginationSvc.set_busy true

      $http.post('/api/feeds.json', feed:{url: url})
      .success (data)->
        startPageSvc.show_start_page()
      .error (data, status)->
        if status == 403
          # User just attempted to subscribe to a blacklisted url
          timerFlagSvc.start 'blacklisted_url'
          startPageSvc.show_start_page()
        else
          entriesPaginationSvc.set_busy false
          # Show alert
          startPageSvc.show_start_page()
          timerFlagSvc.start 'error_subscribing'

  unsubscribe: ->
    current_feed = $rootScope.current_feed
    if current_feed
      # Before deleting from the global scope, save some data we'll need later
      folder_id = current_feed.folder_id
      path = "/api/feeds/#{current_feed.id}.json"

      $rootScope.subscribed_feeds_count -= 1

      # Tell the model that no feed is currently selected.
      startPageSvc.show_start_page()

      # Remove feed from feeds list
      cleanupSvc.remove_feed current_feed.id
      favicoSvc.update_unread_badge()

      # Reset the timer that updates feeds every minute, to give the server time to
      # actually delete the feed subscription before the next update
      feedsFoldersSvc.reset_refresh_timer()

      $http.delete(path)
      .success ->
        # If there are no other feeds in the folder, remove it from the scope
        if folder_id != 'none'
          $http.get("/api/folders/#{folder_id}/feeds.json?include_read=true")
          .success (data)->
            # Check if there are other feeds in the folder
            remove_folder = true
            for feed in data
              remove_folder = false if feed.id != current_feed.id
            cleanupSvc.remove_folder folder_id if remove_folder
          .error (data, status)->
            if status == 404
              # This probably means job has already been performed and folder deleted from the db
              cleanupSvc.remove_folder folder_id
            else if status != 0
              timerFlagSvc.start 'error_loading_feeds'
      .error (data, status)->
        timerFlagSvc.start 'error_unsubscribing' if status!=0

]