########################################################
# AngularJS service to enable keyboard shortcuts.
########################################################

angular.module('feedbunch').service 'keyboardShortcutsSvc',
['$rootScope', 'highlightedEntrySvc', 'highlightedSidebarLinkSvc','entrySvc', 'startPageSvc', 'currentFeedSvc',
'currentFolderSvc', 'findSvc', 'feedsFoldersSvc', 'readSvc', 'menuCollapseSvc',
($rootScope, highlightedEntrySvc, highlightedSidebarLinkSvc, entrySvc, startPageSvc, currentFeedSvc,
currentFolderSvc, findSvc, feedsFoldersSvc, readSvc, menuCollapseSvc)->

  #---------------------------------------------
  # Start responding to keyboard shortcuts
  #---------------------------------------------
  start: ->
    $(document).keypress (event)->
      # enter=13, spacebar=32, j=106, k=107, h=104, l=108, d=100, a=97, r=114
      if event.which in [13, 32, 104, 108, 106, 107, 100, 97, 114]

        # If a keyboard shortcut is used, stop highlighting entries on mousover until user actually moves the mouse.
        # This prevents accidental mouseover events when autoscrolling.
        $rootScope.mouseover_highlight_disabled = true
        $(window).on 'mousemove', ->
          $rootScope.mouseover_highlight_disabled = false
          # unbind mousemove handler, for performance reasons
          $(window).off 'mousemove'

        # shortcuts related to entries
        if $rootScope.entries
          # next entry
          highlightedEntrySvc.next() if event.which == 106

          # previous entry
          highlightedEntrySvc.previous() if event.which == 107

          # toggle open/close state of entry
          entrySvc.toggle_open_entry highlightedEntrySvc.get() if event.which == 32

          # mark all entries as read
          entrySvc.mark_all_read() if event.which == 97

          # toggle read/unread state of currently highlighted entry
          if event.which == 114
            entry = highlightedEntrySvc.get()
            if entry.read
              entrySvc.unread_entry entry
            else
              entrySvc.read_entry entry

        # next link in sidebar
        highlightedSidebarLinkSvc.next() if event.which == 108

        # previous link in sidebar
        highlightedSidebarLinkSvc.previous() if event.which == 104

        # select the currently highlighted link (feed or folder) in the sidebar for reading
        if event.which == 13
          highlighted_link = highlightedSidebarLinkSvc.get()
          if highlighted_link.id == 'start'
            startPageSvc.show_start_page()
          else if highlighted_link.type == 'feed'
            feed = findSvc.find_feed highlighted_link.id
            currentFeedSvc.set feed if feed?
          else if highlighted_link.type == 'folder'
            folder = findSvc.find_folder highlighted_link.id
            currentFolderSvc.set folder if folder?

        # toggle show/hide read entries
        if event.which == 100
          if $rootScope.show_read
            # hide read entries
            feedsFoldersSvc.hide_read()
            readSvc.read_entries_page()
            menuCollapseSvc.close()
          else
            # show read entries
            feedsFoldersSvc.show_read()
            readSvc.read_entries_page()
            menuCollapseSvc.close()

        event.preventDefault()

  #---------------------------------------------
  # Start responding to keyboard shortcuts
  #---------------------------------------------
  stop: ->
    $(document).off 'keypress'
]