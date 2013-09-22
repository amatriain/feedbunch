########################################################
# AngularJS controller file
########################################################

angular.module('feedbunch').controller 'FeedbunchCtrl',
['$rootScope', '$scope', '$http', '$timeout', '$filter', ($rootScope, $scope, $http, $timeout, $filter)->

  # Load folders and feeds via AJAX on startup
  $http.get('/folders.json').success (data)->
    $scope.folders = data

  $http.get('/feeds.json').success (data)->
    $scope.feeds = data

  #--------------------------------------------
  # Function to filter feeds in a given folder
  #--------------------------------------------

  $scope.feed_in_folder = (folder)->
    return (feed)->
      if folder.id == 'all'
        return true
      else
        return folder.id == feed.folder_id

  #--------------------------------------------
  # Function to show the start page
  #--------------------------------------------

  $scope.show_start_page = ->
    unset_current_feed()
    $scope.loading_entries = false

  #--------------------------------------------
  # Function to convert an entry's id to an integer, for filtering purposes
  #--------------------------------------------

  $scope.entry_int_id = (entry)->
    return parseInt entry.id

  #--------------------------------------------
  # Unsubscribe from a feed
  #--------------------------------------------

  $scope.unsubscribe = ->
    # Delete feed model from the scope
    index = $scope.feeds.indexOf $rootScope.current_feed
    $scope.feeds.splice index, 1 if index != -1

    # Before deleting from the global scope, save some data we'll need later
    path = "/feeds/#{$rootScope.current_feed.id}.json"
    unread_entries = $rootScope.current_feed.unread_entries
    folder_id = $rootScope.current_feed.folder_id

    # Update folders
    find_folder('all').unread_entries -= unread_entries
    feed_removed_from_folder $rootScope.current_feed, folder_id

    # Tell the model that no feed is currently selected.
    unset_current_feed()

    $http.delete(path)
    .error ->
      # Show alert
      $rootScope.error_unsubscribing = true
      # Close alert after 5 seconds
      $timeout ->
        $rootScope.error_unsubscribing = false
      , 5000

  #--------------------------------------------
  # Subscribe to a feed
  #--------------------------------------------

  $scope.subscribe = ->
    $("#subscribe-feed-popup").modal 'hide'

    if $scope.subscription_url
      unset_current_feed()
      $scope.loading_entries = true

      $http.post('/feeds.json', feed:{url: $scope.subscription_url})
      .success (data)->
        $scope.loading_entries = false
        $scope.feeds.push data
        $scope.read_feed data
        find_folder('all').unread_entries += data.unread_entries
      .error (data, status)->
        $scope.loading_entries = false
        # Show alert
        if status == 304
          $rootScope.error_already_subscribed = true
          # Close alert after 5 seconds
          $timeout ->
            $rootScope.error_already_subscribed = false
          , 5000
        else
          $rootScope.error_subscribing = true
          # Close alert after 5 seconds
          $timeout ->
            $rootScope.error_subscribing = false
          , 5000
    $scope.subscription_url = null

  #--------------------------------------------
  # Remove a feed from a folder
  #--------------------------------------------

  $scope.remove_from_folder = ->
    folder_id = $rootScope.current_feed.folder_id
    $rootScope.current_feed.folder_id = 'none'
    feed_removed_from_folder $rootScope.current_feed, folder_id

    $http.put('/folders/none.json', folder: {feed_id: $rootScope.current_feed.id})
    .error ->
      # Show alert
      $rootScope.error_managing_folders = true
      # Close alert after 5 seconds
      $timeout ->
        $rootScope.error_managing_folders = false
      , 5000

  #--------------------------------------------
  # Move a feed to an already existing folder
  #--------------------------------------------

  $scope.move_to_folder = (folder)->
    old_folder_id = $rootScope.current_feed.folder_id
    $rootScope.current_feed.folder_id = folder.id
    feed_removed_from_folder $rootScope.current_feed, old_folder_id
    folder.unread_entries += $rootScope.current_feed.unread_entries

    $http.put("/folders/#{folder.id}.json", folder: {feed_id: $rootScope.current_feed.id})
    .error ->
      # Show alert
      $rootScope.error_managing_folders = true
      # Close alert after 5 seconds
      $timeout ->
        $rootScope.error_managing_folders = false
      , 5000

  #--------------------------------------------
  # Move a feed to a new folder
  #--------------------------------------------

  $scope.move_to_new_folder = ()->
    $("#new-folder-popup").modal 'hide'

    if $scope.new_folder_title
      $http.post("/folders.json", folder: {feed_id: $rootScope.current_feed.id, title: $scope.new_folder_title})
      .success (data)->
        $scope.folders.push data
        old_folder_id = $rootScope.current_feed.folder_id
        $rootScope.current_feed.folder_id = data.id
        feed_removed_from_folder $rootScope.current_feed, old_folder_id
      .error (data, status)->
        if status == 304
          # Show alert
          $rootScope.error_already_existing_folder = true
          # Close alert after 5 seconds
          $timeout ->
            $rootScope.error_already_existing_folder = false
          , 5000
        else
          # Show alert
          $rootScope.error_creating_folder = true
          # Close alert after 5 seconds
          $timeout ->
            $rootScope.error_creating_folder = false
          , 5000
    $scope.new_folder_title = null

  #--------------------------------------------
  # Load a feed's unread entries
  #--------------------------------------------

  $scope.read_feed = (feed)->
    set_current_feed feed
    load_feed feed, false

  #--------------------------------------------
  # Load a folder's unread entries
  #--------------------------------------------

  $scope.read_folder = (folder)->
    set_current_folder folder
    $scope.loading_entries = true

    $http.get("/folders/#{folder.id}.json")
    .success (data)->
        $scope.loading_entries = false
        $scope.entries = data["entries"]
    .error (data,status)->
      $scope.loading_entries = false
      if status == 404
        $rootScope.error_no_entries = true
        # Close alert after 5 seconds
        $timeout ->
          $rootScope.error_no_entries = false
        , 5000
      else
        $rootScope.error_loading_entries = true
        # Close alert after 5 seconds
        $timeout ->
          $rootScope.error_loading_entries = false
        , 5000

  #--------------------------------------------
  # Load all of a feed's entries regardless of state
  #--------------------------------------------

  $scope.read_all_entries = ->
    unset_open_entry()
    load_feed $rootScope.current_feed, true

  #--------------------------------------------
  # Refresh a feed and load its unread entries
  #--------------------------------------------

  $scope.refresh_feed = ->
    unset_open_entry()
    $scope.loading_entries = true

    $http.put("/feeds/#{$rootScope.current_feed.id}.json")
    .success (data)->
      $scope.loading_entries = false
      $scope.entries = data["entries"]
      $rootScope.current_feed.unread_entries = data["unread_entries"]
    .error ->
      $scope.loading_entries = false
      if status == 404
        $rootScope.error_no_entries = true
        # Close alert after 5 seconds
        $timeout ->
          $rootScope.error_no_entries = false
        , 5000
      else
        # Show alert
        $rootScope.error_refreshing_feed = true
        # Close alert after 5 seconds
        $timeout ->
          $rootScope.error_refreshing_feed = false
        , 5000

  #--------------------------------------------
  # Mark a single entry as read
  #--------------------------------------------

  $scope.read_entry = (entry)->
    if $rootScope.open_entry == entry
      # User is closing the open entry, do nothing
      unset_open_entry()
    else
      set_open_entry entry
      if !entry.read
        # User is opening an unread entry, mark it as read
        change_entries_state [entry], true

  #--------------------------------------------
  # Mark all entries as read
  #--------------------------------------------

  $scope.mark_all_read = ->
    change_entries_state $scope.entries, true

  #--------------------------------------------
  # Mark a single entry as unread
  #--------------------------------------------

  $scope.unread_entry = ->
    if $rootScope.open_entry.read
      change_entries_state [$rootScope.open_entry], false


  #--------------------------------------------
  # Load a feed's entries
  #--------------------------------------------

  load_feed = (feed, include_read_entries)->
    $scope.loading_entries = true

    $http.get("/feeds/#{feed.id}.json?include_read=#{include_read_entries}")
    .success (data)->
      $scope.loading_entries = false
      $scope.entries = data["entries"]
      feed.unread_entries = data["unread_entries"]
    .error (data,status)->
      unset_current_feed()
      $scope.loading_entries = false
      if status == 404
        $rootScope.error_no_entries = true
        # Close alert after 5 seconds
        $timeout ->
          $rootScope.error_no_entries = false
        , 5000
      else
        $rootScope.error_loading_entries = true
        # Close alert after 5 seconds
        $timeout ->
          $rootScope.error_loading_entries = false
        , 5000

  #--------------------------------------------
  # Mark an array of entries as read or unread.
  # Receives as arguments an array of entries and a boolean indicating whether to mark
  # them as read (true) or unread (false).
  #--------------------------------------------

  change_entries_state = (entries, read)->
    # Mark entries as read or unread in the model
    for entry in entries
      entry.read = read

    # Get array of IDs for the entries
    entry_ids = entries.map (entry) -> entry.id

    if read
      state = "read"
      # Decrement the unread entries count for the feed
      $rootScope.current_feed.unread_entries -= entries.length
    else
      state = "unread"
      # Increment the unread entries count for the feed
      $rootScope.current_feed.unread_entries += entries.length

    $http.put("/entries/update.json", entries: {ids: entry_ids, state: state})
    .error ->
      # Show alert
      $rootScope.error_changing_entry_state = true
      # Close alert after 5 seconds
      $timeout ->
        $rootScope.error_changing_entry_state = false
      , 5000

  #--------------------------------------------
  # Return a folder object given its id
  #--------------------------------------------

  find_folder = (id)->
    if id == 'none'
      return null
    else
      folders = $filter('filter') $scope.folders, {id: id}
      return folders[0]

  #--------------------------------------------
  # Return an array of feeds in a folder given the folder id
  #--------------------------------------------

  find_folder_feeds = (folder_id)->
    return $filter('filter') $scope.feeds, {folder_id: folder_id}

  #--------------------------------------------
  # Update the model to account for a feed having been removed from a folder
  #--------------------------------------------

  feed_removed_from_folder = (feed, folder_id)->
    folder = find_folder folder_id
    if folder != null
      # Remove folder if it's empty
      if find_folder_feeds(folder_id).length == 0
        index = $scope.folders.indexOf folder
        $scope.folders.splice index, 1 if index != -1
      # Otherwise update unread entries in folder
      else
        folder.unread_entries -= feed.unread_entries

  #--------------------------------------------
  # Store the currently selected feed in the global scope
  #--------------------------------------------

  set_current_feed = (feed)->
    unset_current_folder()
    unset_open_entry()
    $rootScope.current_feed = feed

  #--------------------------------------------
  # Unset the currently selected feed in the global scope
  #--------------------------------------------

  unset_current_feed = ->
    unset_open_entry()
    $rootScope.current_feed = null

  #--------------------------------------------
  # Store the currently selected folder in the global scope
  #--------------------------------------------

  set_current_folder = (folder)->
    unset_current_feed()
    unset_open_entry()
    $rootScope.current_folder = folder

  #--------------------------------------------
  # Unset the currently selected folder in the global scope
  #--------------------------------------------

  unset_current_folder = ->
    unset_open_entry()
    $rootScope.current_folder = null

  #--------------------------------------------
  # Store the currently open entry in the global scope
  #--------------------------------------------

  set_open_entry = (entry)->
    $rootScope.open_entry = entry

  #--------------------------------------------
  # Unset the currently open entry in the global scope
  #--------------------------------------------

  unset_open_entry = ->
    $rootScope.open_entry = null

]