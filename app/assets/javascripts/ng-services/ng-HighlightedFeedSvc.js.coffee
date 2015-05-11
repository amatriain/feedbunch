########################################################
# AngularJS service for the currently highlighted feed.
########################################################

angular.module('feedbunch').service 'highlightedFeedSvc',
['$rootScope', '$filter', 'animationsSvc', 'findSvc',
($rootScope, $filter, animationsSvc, findSvc)->

  #---------------------------------------------
  # PRIVATE FUNCTION: Set the currently highlighted feed
  #---------------------------------------------
  set = (feed)->
    if feed == 'start'
      $rootScope.highlighted_feed_id = 'start'
      start_link = $('#start-page')
      start_link.addClass 'highlighted-feed'
      $('#folders-list a[data-feed-id].highlighted-feed').removeClass 'highlighted-feed'
    else
      $rootScope.highlighted_feed_id = feed.id
      feed_link = $("#folders-list a[data-feed-id=#{feed.id}]")
      # Add CSS class "highlighted-feed" only to currently highlighted feed
      feed_link.addClass 'highlighted-feed'
      $("#folders-list a[data-feed-id!=#{feed.id}].highlighted-feed").removeClass 'highlighted-feed'

  service =

    #---------------------------------------------
    # Set the "start" link in the sidebar as the currently highlighted one
    #---------------------------------------------
    reset: ->
      set 'start'

    #---------------------------------------------
    # Set the currently highlighted feed
    #---------------------------------------------
    set: set

    #---------------------------------------------
    # Get the currently highlighted feed
    #---------------------------------------------
    get: ->
      return $rootScope.highlighted_feed_id

    #---------------------------------------------
    # Highlight the next feed (below current one)
    #---------------------------------------------
    next: ->
      current_feed = findSvc.find_feed $rootScope.highlighted_feed_id
      current_folder = findSvc.find_folder current_feed.folder_id
      current_folder_feeds = findSvc.find_folder_feeds current_folder

      # order folder feeds by title, to see if the next feed will be in another folder
      ordered_current_folder_feeds = $filter('orderBy') current_folder_feeds, 'title'

      index_feed = ordered_current_folder_feeds.indexOf current_feed
      if index_feed >= 0 && index_feed < (ordered_current_folder_feeds.length - 1)
        # Next feed is in the same folder as the currently highlighted one
        next_feed = ordered_current_folder_feeds[index_feed + 1]
        set next_feed
        # TODO open folder if necessary
        # TODO scroll sidebar to show feed in the viewport if necessary
      else
        # Next feed is in the next folder, if any
        # TODO handle special case: current folder is 'none'
        ordered_folders = $filter('orderBy') $rootScope.folders, 'title'
        index_folder = ordered_folders.indexOf current_folder
        if index_folder >= 0 && index_folder < (ordered_folders.length - 1)
          # Next feed is in the next folder
          # TODO close current folder, open next folder
          next_folder = ordered_folders[index_folder + 1]
          next_folder_feeds = findSvc.find_folder_feeds next_folder
          # TODO handle special case: next folder has no feeds
          ordered_next_folder_feeds = $filter('orderBy') next_folder_feeds, 'title'
          # TODO select 'all subscriptions' link of next folder
          # TODO scroll sidebar to show feed in the viewport if necessary


    #---------------------------------------------
    # Highlight the previous feed (above current one)
    #---------------------------------------------
    # TODO implementation
#    previous: ->
#      index = $rootScope.entries.indexOf $rootScope.highlighted_entry
#      if index > 0 && index < $rootScope.entries.length
#        previous_entry = $rootScope.entries[index - 1]
#        set previous_entry
#        # Scroll page so that highlighted entry is visible, if necessary
#        animationsSvc.entry_scroll_up previous_entry

  return service
]