########################################################
# AngularJS service to load feeds and folders data in the root scope
########################################################

angular.module('feedbunch').service 'feedsFoldersSvc',
['$rootScope', '$http', '$filter', '$timeout', 'timerFlagSvc', 'findSvc', 'entriesPaginationSvc'
($rootScope, $http, $filter, $timeout, timerFlagSvc, findSvc, entriesPaginationSvc)->

  #--------------------------------------------
  # PRIVATE FUNCTION: Load feeds. Reads the boolean flag "show_read" to know if
  # we want to load all feeds (true) or only feeds with unread entries (false).
  #--------------------------------------------
  load_feeds = ->
    $http.get("/feeds.json?include_read=#{$rootScope.show_read}")
    .success (data)->
      if !$rootScope.feeds || $rootScope.feeds?.length==0
        # If there are no feeds in scope, just store the feeds returned.
        $rootScope.feeds = data
      else
        # If there are feeds already loaded in scope, replace them with the ones returned, without removing any feed
        # (i.e. if a feed in scope is not among the returned feeds, do not remove it from scope).
        for feed_new in data
          feed_old = findSvc.find_feed feed_new.id
          if feed_old
            feed_old.unread_entries = feed_new.unread_entries
          else
            $rootScope.feeds.push feed_new
      $rootScope.feeds_loaded = true
    .error ->
      timerFlagSvc.start 'error_loading_feeds'

  #--------------------------------------------
  # PRIVATE FUNCTION: Load feeds every minute.
  #--------------------------------------------
  refresh_feeds = ->
    $timeout ->
      load_feeds()
      refresh_feeds()
    , 60000

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
  # PRIVATE FUNCTION: Load feeds and folders.
  #--------------------------------------------
  load_data = ->
    load_folders()
    load_feeds()

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

  #--------------------------------------------
  # PRIVATE FUNCTION: Remove feeds without unread entries from the root scope, unless the user has
  # selected to display all feeds including read ones.
  # If the user clicks on the same feed or on its folder, do nothing.
  #--------------------------------------------
  remove_read_feeds = ->
    if !$rootScope.show_read
      read_feeds = $filter('filter') $rootScope.feeds, (feed)->
        return feed.unread_entries <= 0
      for feed in read_feeds
        if $rootScope.current_feed?.id != feed.id && $rootScope.current_folder?.id != feed.folder_id
          # Delete feed from the scope
          index = $rootScope.feeds.indexOf feed
          $rootScope.feeds.splice index, 1 if index != -1

  service =

    #---------------------------------------------
    # Set to true a flag that makes all feeds (whether they have unread entries or not) and
    # all entries (whether they are read or unread) to be shown.
    #---------------------------------------------
    show_read: ->
      $rootScope.show_read = true
      entriesPaginationSvc.reset_entries()
      $rootScope.feeds_loaded = false
      load_feeds()

    #---------------------------------------------
    # Set to false a flag that makes only feeds with unread entries and
    # unread entries to be shown.
    #---------------------------------------------
    hide_read: ->
      $rootScope.show_read = false
      entriesPaginationSvc.reset_entries()
      $rootScope.feeds_loaded = false
      remove_read_feeds()
      load_feeds()

    #---------------------------------------------
    # Load feeds and folders via AJAX into the root scope.
    # Start running a refresh of feeds every minute while the app is open.
    #---------------------------------------------
    start_refresh_data: ->
      $rootScope.feeds_loaded = false
      $rootScope.folders_loaded = false
      $rootScope.show_read = false
      load_data()
      refresh_feeds()

    #---------------------------------------------
    # Load feeds and folders via AJAX into the root scope.
    # Only feeds with unread entries are retrieved.
    #---------------------------------------------
    load_data: load_data

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
    remove_read_feeds: remove_read_feeds

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
      if $rootScope.feeds
        for feed in $rootScope.feeds
          sum += feed.unread_entries
      return sum

  return service
]