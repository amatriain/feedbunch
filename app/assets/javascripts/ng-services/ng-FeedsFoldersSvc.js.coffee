########################################################
# AngularJS service to load feeds and folders data in the root scope
########################################################

angular.module('feedbunch').service 'feedsFoldersSvc',
['$rootScope', '$http', '$filter', 'timerFlagSvc', 'findSvc', 'entriesPaginationSvc'
($rootScope, $http, $filter, timerFlagSvc, findSvc, entriesPaginationSvc)->

  #--------------------------------------------
  # PRIVATE FUNCTION: Load feeds. Reads the boolean flag "show_read" to know if
  # we want to load all feeds (true) or only feeds with unread entries (false).
  #--------------------------------------------
  load_feeds = ->
    $rootScope.feeds_loaded = false
    $http.get("/feeds.json?include_read=#{$rootScope.show_read}")
    .success (data)->
      $rootScope.feeds = data
      $rootScope.feeds_loaded = true
    .error ->
      timerFlagSvc.start 'error_loading_feeds'

  #--------------------------------------------
  # PRIVATE FUNCTION: Load folders.
  #--------------------------------------------
  load_folders = ->
    $http.get('/folders.json')
    .success (data)->
      $rootScope.folders = data
      $rootScope.folders_loaded = true
    .error ->
      timerFlagSvc.start 'error_loading_folders'

  #--------------------------------------------
  # PRIVATE FUNCTION: Update the model to account for a feed having been removed from a folder
  #--------------------------------------------
  feed_removed = (folder_id)->
    folder = findSvc.find_folder folder_id
    if folder != null
      # Remove folder if it's empty
      if findSvc.find_folder_feeds(folder).length == 0
        index = $rootScope.folders.indexOf folder
        $rootScope.folders.splice index, 1 if index != -1

  #---------------------------------------------
  # PRIVATE FUNCTION: Remove a feed from the feeds array.
  #---------------------------------------------
  remove_feed = (feed)->
    folder_id = feed.folder_id
    # Delete feed model from the scope
    index = $rootScope.feeds.indexOf feed
    $rootScope.feeds.splice index, 1 if index != -1
    # Update folders
    feed_removed folder_id

  service =

    #---------------------------------------------
    # Set to true a flag that makes all feeds (whether they have unread entries or not) and
    # all entries (whether they are read or unread) to be shown.
    #---------------------------------------------
    show_read: ->
      $rootScope.show_read = true
      entriesPaginationSvc.reset_entries()
      load_feeds()

    #---------------------------------------------
    # Set to false a flag that makes only feeds with unread entries and
    # unread entries to be shown.
    #---------------------------------------------
    hide_read: ->
      $rootScope.show_read = false
      entriesPaginationSvc.reset_entries()
      load_feeds()

    #---------------------------------------------
    # Load feeds and folders via AJAX into the root scope at startup.
    # Only feeds with unread entries are retrieved.
    #---------------------------------------------
    load_data: ->
      $rootScope.show_read = false
      load_folders()
      load_feeds()

    #---------------------------------------------
    # Load feeds via AJAX into the root scope.
    #---------------------------------------------
    load_feeds: load_feeds

    #--------------------------------------------
    # Load folders via AJAX into the root scope.
    #--------------------------------------------
    load_folders: load_folders

    #---------------------------------------------
    # Push a feed in the feeds array. If the feeds array is empty, create it anew,
    # ensuring angularjs ng-repeat is triggered.
    #---------------------------------------------
    add_feed: (feed)->
      if $rootScope.feeds.length == 0
        $rootScope.feeds = [feed]
      else
        $rootScope.feeds.push feed

    #---------------------------------------------
    # Push a folder in the folders array. If the folders array is empty, create it anew,
    # ensuring angularjs ng-repeat is triggered.
    #---------------------------------------------
    add_folder: (folder)->
      if $rootScope.folders.length == 0
        $rootScope.folders = [folder]
      else
        $rootScope.folders.push folder

    #---------------------------------------------
    # Remove a feed from the feeds array.
    #---------------------------------------------
    remove_feed: remove_feed

    #--------------------------------------------
    # Remove feeds without unread entries from the root scope, unless the user has
    # selected to display all feeds including read ones.
    # If the user clicks on the same feed or on its folder, do nothing.
    #--------------------------------------------
    remove_read_feeds: ->
      if !$rootScope.show_read
        read_feeds = $filter('filter') $rootScope.feeds, (feed)->
          return feed.unread_entries <= 0
        for feed in read_feeds
          if $rootScope.current_feed?.id != feed.id && $rootScope.current_folder?.id != feed.folder_id
            # Delete feed from the scope
            index = $rootScope.feeds.indexOf feed
            $rootScope.feeds.splice index, 1 if index != -1

    #--------------------------------------------
    # Count the number of unread entries in a folder
    #--------------------------------------------
    folder_unread_entries: (folder)->
      sum = 0
      feeds = findSvc.find_folder_feeds folder
      for feed in feeds
        sum += feed.unread_entries
      return sum

    #--------------------------------------------
    # Count the total number of unread entries in feeds
    #--------------------------------------------
    total_unread_entries: ->
      sum = 0
      for feed in $rootScope.feeds
        sum += feed.unread_entries
      return sum

  return service
]