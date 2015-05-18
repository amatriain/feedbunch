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
      kb_shortcuts_array = []
      kb_shortcuts_array.push val for key, val of $rootScope.kb_shortcuts

      if event.which in kb_shortcuts_array

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
          highlightedEntrySvc.next() if event.which == $rootScope.kb_shortcuts["entries_down"]

          # previous entry
          highlightedEntrySvc.previous() if event.which == $rootScope.kb_shortcuts["entries_up"]

          # toggle open/close state of entry
          entrySvc.toggle_open_entry highlightedEntrySvc.get() if event.which == $rootScope.kb_shortcuts["toggle_open_entry"]

          # mark all entries as read
          entrySvc.mark_all_read() if event.which == $rootScope.kb_shortcuts["mark_all_read"]

          # toggle read/unread state of currently highlighted entry
          if event.which == $rootScope.kb_shortcuts["toggle_read_entry"]
            entry = highlightedEntrySvc.get()
            if entry.read
              entrySvc.unread_entry entry
            else
              entrySvc.read_entry entry

        # next link in sidebar
        highlightedSidebarLinkSvc.next() if event.which == $rootScope.kb_shortcuts["sidebar_link_down"]

        # previous link in sidebar
        highlightedSidebarLinkSvc.previous() if event.which == $rootScope.kb_shortcuts["sidebar_link_up"]

        # select the currently highlighted link (feed or folder) in the sidebar for reading
        if event.which == $rootScope.kb_shortcuts["select_sidebar_link"]
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
        if event.which == $rootScope.kb_shortcuts["toggle_show_read"]
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