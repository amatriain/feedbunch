########################################################
# AngularJS service to enable keyboard shortcuts.
########################################################

angular.module('feedbunch').service 'keyboardShortcutsSvc',
['$rootScope', 'highlightedEntrySvc', 'highlightedSidebarLinkSvc','entrySvc', 'startPageSvc', 'currentFeedSvc',
'currentFolderSvc', 'findSvc', 'showHideReadSvc', 'loadEntriesSvc', 'menuCollapseSvc', 'tooltipSvc',
($rootScope, highlightedEntrySvc, highlightedSidebarLinkSvc, entrySvc, startPageSvc, currentFeedSvc,
currentFolderSvc, findSvc, showHideReadSvc, loadEntriesSvc, menuCollapseSvc, tooltipSvc)->

  # Boolean flag to indicate whether keyboard shortcuts are currently enabled
  keyboard_shortcuts_running = true

  #---------------------------------------------
  # Initialize the service. The $rootScope.kb_shortcuts_enabled flag controls the whole keyboard shortcuts feature;
  # if it's false, this means that the user has disabled it in the user config.
  #---------------------------------------------
  init: ->
    keyboard_shortcuts_running = $rootScope.kb_shortcuts_enabled

  #---------------------------------------------
  # Start responding to keyboard shortcuts, if enabled.
    # If $rootScope.kb_shortcuts_enabled is false, this method does nothing.
  #---------------------------------------------
  start: ->
    keyboard_shortcuts_running = true if $rootScope.kb_shortcuts_enabled

  #---------------------------------------------
  # Stop responding to keyboard shortcuts, if keyboard shortcuts are enabled.
  # if $rootScope.kb_shortcuts_enabled is false, this method does nothing.
  #---------------------------------------------
  stop: ->
    keyboard_shortcuts_running = false

  #---------------------------------------------
  # Respond to a keypress
  #---------------------------------------------
  key_pressed: (event)->
    if keyboard_shortcuts_running
      # If a keyboard shortcut is used, stop highlighting entries on mousover until user actually moves the mouse.
      # This prevents accidental mouseover events when autoscrolling.
      $rootScope.mouseover_highlight_disabled = true
      $(window).on 'mousemove', ->
        $rootScope.mouseover_highlight_disabled = false
        # unbind mousemove handler, for performance reasons
        $(window).off 'mousemove'

      switch event.which
        when $rootScope.kb_shortcuts["toggle_open_entry"] then entrySvc.toggle_open_entry highlightedEntrySvc.get() #open/close entry
        when $rootScope.kb_shortcuts["toggle_read_entry"] # mark entry as read/unread
          entry = highlightedEntrySvc.get()
          if entry?
            if entry.read
              entrySvc.unread_entry entry
            else
              entrySvc.read_entry entry
        when $rootScope.kb_shortcuts["mark_all_read"] then entrySvc.mark_all_read() # mark all as read
        when $rootScope.kb_shortcuts["entries_down"] then highlightedEntrySvc.next() # next entry
        when $rootScope.kb_shortcuts["entries_up"] then  highlightedEntrySvc.previous() # previous entry
        when $rootScope.kb_shortcuts["sidebar_link_down"] then highlightedSidebarLinkSvc.next() # next sidebar link
        when $rootScope.kb_shortcuts["sidebar_link_up"] then highlightedSidebarLinkSvc.previous() # previous sidebar link
        when $rootScope.kb_shortcuts["select_sidebar_link"] # read current sidebar link
          highlighted_link = highlightedSidebarLinkSvc.get()
          if highlighted_link?
            # Force entry tooltips to hide, because entries list will be cleared without a focus change
            tooltipSvc.all_entries_tooltips_hide()
            if highlighted_link.id == 'start'
              startPageSvc.show_start_page()
            else if highlighted_link.type == 'feed'
              feed = findSvc.find_feed highlighted_link.id
              currentFeedSvc.set feed if feed?
            else if highlighted_link.type == 'folder'
              folder = findSvc.find_folder highlighted_link.id
              currentFolderSvc.set folder if folder?
        when $rootScope.kb_shortcuts["toggle_show_read"] # show/hide read entries
          # Force entry tooltips to hide, because entries list will change without a focus change
          tooltipSvc.all_entries_tooltips_hide()
          if $rootScope.show_read
            showHideReadSvc.hide_read() # hide read entries
          else
            showHideReadSvc.show_read() # show read entries
          loadEntriesSvc.read_entries_page()
          menuCollapseSvc.close()
        else
          return

      event.preventDefault()


]