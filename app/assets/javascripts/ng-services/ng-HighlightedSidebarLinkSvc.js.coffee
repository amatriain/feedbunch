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
    $("#sidebar a.highlighted-link").removeClass 'highlighted-link'
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
      folder_link = $("#folders-list #feeds-#{id} a[data-feed-id='all']")
      single_highlighted_link folder_link

  #---------------------------------------------
  # PRIVATE FUNCTION: returns an array with the links in the sidebar, in the same order they are visible.
  # Each link is represented by an object with these attributes:
  # - id: the value START if it's the "Start" link, or the ID of the feed or folder if it's a feed or folder link
  # - type: either FEED or FOLDER if it's a feed or folder link, or null if it's the "Start" link
  #---------------------------------------------
  sidebar_links = ->
    links = []
    links << {id: START, type: null}

    no_folder_feeds = findSvc.find_folder_feeds 'none'
    ordered_feeds = $filter('orderBy') no_folder_feeds, 'title'
    links << {id: 'none', type: FOLDER}
    for feed in ordered_feeds
      links << {id: feed.id, type: FEED}

    ordered_folders = $filter('orderBy') $rootScope.folders, 'title'
    for folder in ordered_folders
      folder_feeds = findSvc.find_folder_feeds folder
      # The "All subscriptions" link for a folder is visible only if there is more than 1 feed in it
      links << {id: folder.id, type: FOLDER} if folder_feeds.length > 1
      ordered_feeds = $filter('orderBy') folder_feeds, 'title'
      for feed in ordered_feeds
        links << {id: feed.id, type: FEED}

    return links

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
      if folder == 'all'
        id = 'all'
      else
        id = folder.id
      set id, FOLDER

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
      links = sidebar_links()
      index = links.indexOf $rootScope.highlighted_sidebar_link
      if index >= 0 && index < (links.length - 1)
        next_link = links[index + 1]
        set next_link
        # TODO open folder if necessary
        # TODO autoscroll sidebar if necessary

    #---------------------------------------------
    # Highlight the previous link (above current one)
    #---------------------------------------------

    previous: ->
      links = sidebar_links()
      index = links.indexOf $rootScope.highlighted_sidebar_link
      if index > 0 && index < links.length
        previous_link = links[index - 1]
        set previous_link
        # TODO open folder if necessary
        # TODO autoscroll sidebar if necessary

  return service
]