########################################################
# AngularJS service to enable keyboard shortcuts.
########################################################

angular.module('feedbunch').service 'keyboardShortcutsSvc',
['$rootScope', 'highlightedEntrySvc', 'entrySvc',
($rootScope, highlightedEntrySvc, entrySvc)->

  #---------------------------------------------
  # Start responding to keyboard shortcuts
  #---------------------------------------------
  start: ->
    $(document).keypress (event)->
      # spacebar=32, j=106, k=107
      if event.which in [32, 106, 107]
        # If a keyboard shortcut is used, stop highlighting entries on mousover until user actually moves the mouse.
        # This prevents accidental mouseover events when autoscrolling.
        $rootScope.mouseover_highlight_disabled = true
        $(window).on 'mousemove', ->
          $rootScope.mouseover_highlight_disabled = false
          # unbind mousemove handler, for performance reasons
          $(window).off 'mousemove'

        if $rootScope.entries
          highlightedEntrySvc.next() if event.which == 106
          highlightedEntrySvc.previous() if event.which == 107
          entrySvc.toggle_open_entry highlightedEntrySvc.get() if event.which == 32
        event.preventDefault()

  #---------------------------------------------
  # Start responding to keyboard shortcuts
  #---------------------------------------------
  stop: ->
    $(document).off 'keypress'
]