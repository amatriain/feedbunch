########################################################
# AngularJS controllers file
########################################################

angular.module('feedbunch').controller 'FoldersCtrl',
['$rootScope', '$scope', '$http', '$timeout', ($rootScope, $scope, $http, $timeout)->

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
  # Store the currently selected feed in the global scope
  #--------------------------------------------

  $scope.set_current_feed = (feed)->
    $rootScope.current_feed = feed

  #--------------------------------------------
  # Unset the currently selected feed in the global scope
  #--------------------------------------------

  $scope.unset_current_feed = ->
    $rootScope.current_feed = null

  #--------------------------------------------
  # Unsubscribe from a feed
  #--------------------------------------------

  $scope.unsubscribe = ->
    # Delete feed model from the scope
    index = $scope.feeds.indexOf $rootScope.current_feed
    $scope.feeds.splice index, 1 if index != -1

    # Show the start page instead of the current feed
    path = "/feeds/#{$rootScope.current_feed.id}.json"
    $rootScope.current_feed = null

    $http.delete(path).success (data)->
      alert "success"
    .error ->
      # Show alert
      $scope.error_unsubscribing = true
      # Close alert after 5 seconds
      $timeout ->
        $scope.error_unsubscribing = false
      , 5000

  ###
        # Function to handle result returned by the server
        unsubscribe_result = (data, status, xhr) ->
          Feedbunch.update_folder_entry_count "all", data["all_subscriptions"]["sidebar_read_all"]
          if data["old_folder"]
            if data["old_folder"]["deleted"]
              Feedbunch.remove_folder data["old_folder"]["id"]
            else
              Feedbunch.update_folder_entry_count data["old_folder"]["id"], data["old_folder"]["sidebar_read_all"]

        $.post(Feedbunch.current_feed_path, {"_method":"delete"}, unsubscribe_result, 'json')
        .fail ->
            Feedbunch.alertTimedShowHide $("#problem-unsubscribing")

    ###

]