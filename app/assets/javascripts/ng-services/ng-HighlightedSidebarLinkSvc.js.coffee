########################################################
# AngularJS service for the currently highlighted link in the sidebar.
########################################################

angular.module('feedbunch').service 'highlightedSidebarLinkSvc',
['$rootScope', '$filter', 'animationsSvc', 'findSvc',
($rootScope, $filter, animationsSvc, findSvc)->

  #---------------------------------------------
  # PRIVATE CONSTANTS
  #---------------------------------------------
  START = 'start'
  FEED = 'feed'
  FOLDER = 'folder'

  #---------------------------------------------
  # PRIVATE FUNCTION: Highlight a single link in the sidebar.
  # Receives as argument a jquery object for the highlighted link.
  #---------------------------------------------
  single_highlighted_link = (link)->
    $("#folders-list a[data-feed-id].highlighted-feed").removeClass 'highlighted-link'
    link.addClass 'highlighted-link'

  #---------------------------------------------
  # PRIVATE FUNCTION: Set the currently highlighted link.
  # Receives as arguments:
  # - id: if the selected link is the "Start" link, the START constant is passed here.
  # If it's a feed link, it's the feed ID. If it's a folder's "Read all subscriptions" link, it's the folder ID.
  # - type: optional argument. If the id argument is START, this argument will be ignored. Otherwise, it takes the value
  # FEED or FOLDER to indicate if the ID passed corresponds to a feed or a folder.
  #---------------------------------------------
  set = (id, type=null)->
    if id == START
      $rootScope.highlighted_sidebar_link = {id: id, type: null}
      start_link = $('#start-page')
      single_highlighted_link start_link
    else if type == FEED
      $rootScope.highlighted_sidebar_link = {id: id, type: type}
      feed_link = $("#folders-list a[data-feed-id=#{id}]")
      single_highlighted_link feed_link
    else if type == FOLDER
      $rootScope.highlighted_sidebar_link = {id: id, type: type}
      folder_link = $("#folders-list #feeds-#{id} a[data-feed-id='all]")
      single_highlighted_link folder_link

  service =

    #---------------------------------------------
    # Set the "start" link in the sidebar as the currently highlighted one
    #---------------------------------------------
    reset: ->
      set START

    #---------------------------------------------
    # Highlight the link for the passed feed
    #---------------------------------------------
    set_feed: (feed)->
      set feed.id, FEED

    #---------------------------------------------
    # Highlight the link for the passed folder
    #---------------------------------------------
      set_folder: (folder)->
        set folder.id, FOLDER

    #---------------------------------------------
    # Get the currently highlighted link.
    # It returns an object with two attributes:
    # - id: the ID of the feed or folder, if the highlighted link corresponds to a link or folder; or "start" if
    # the highlighted link is the "Start" link
    # - type: either "feed" or "folder" if the highlighted link is a feed or folder; or null if the highlighted link
    # is the "Start" link
    #---------------------------------------------
    get: ->
      return $rootScope.highlighted_sidebar_link

    #---------------------------------------------
    # Highlight the next link (below current one).
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