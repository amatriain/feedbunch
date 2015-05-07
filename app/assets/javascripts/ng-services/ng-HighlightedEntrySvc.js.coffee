########################################################
# AngularJS service for the currently highlighted entry.
########################################################

angular.module('feedbunch').service 'highlightedEntrySvc',
['$rootScope', 'animationsSvc',
($rootScope, animationsSvc)->

  #---------------------------------------------
  # PRIVATE FUNCTION: Set the currently highlighted entry
  #---------------------------------------------
  set = (entry)->
    $rootScope.highlighted_entry = entry

    entry_css_selector = "#feed-entries a[data-entry-id=#{entry.id}]"

    # Add CSS class "highlighted-entry" only to currently highlighted entry
    $('#feed-entries a[data-entry-id].highlighted-entry').removeClass 'highlighted-entry'
    $(entry_css_selector).addClass 'highlighted-entry'

    # Make caret visible only for the currently highlighted entry
    $('i.current-entry:visible').hide()
    $("#{entry_css_selector} i.current-entry").show()

  service =

    #---------------------------------------------
    # Set the first entry in the list as the currently highlighted one
    #---------------------------------------------
    reset: ->
      if $rootScope.entries && $rootScope.entries?.length > 0
        set $rootScope.entries[0]

    #---------------------------------------------
    # Set the currently highlighted entry
    #---------------------------------------------
    set: set

    #---------------------------------------------
    # Get the currently highlighted entry
    #---------------------------------------------
    get: ->
      return $rootScope.highlighted_entry

    #---------------------------------------------
    # Highlight the next entry (below current one)
    #---------------------------------------------
    next: ->
      index = $rootScope.entries.indexOf $rootScope.highlighted_entry
      if index >= 0 && index < ($rootScope.entries.length - 1)
        next_entry = $rootScope.entries[index + 1]
        set next_entry
        # Scroll page so that highlighted entry is visible, if necessary
        animationsSvc.entry_scroll_down next_entry

    #---------------------------------------------
    # Highlight the previous entry (above current one)
    #---------------------------------------------
    previous: ->
      index = $rootScope.entries.indexOf $rootScope.highlighted_entry
      if index > 0 && index < $rootScope.entries.length
        previous_entry = $rootScope.entries[index - 1]
        set previous_entry
        # Scroll page so that highlighted entry is visible, if necessary
        animationsSvc.entry_scroll_up previous_entry

  return service
]