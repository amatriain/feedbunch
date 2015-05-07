########################################################
# AngularJS service for the currently highlighted entry.
########################################################

angular.module('feedbunch').service 'highlightedEntrySvc',
['$rootScope',
($rootScope)->

  #---------------------------------------------
  # PRIVATE FUNCTION: Set the currently highlighted entry
  #---------------------------------------------
  set = (entry)->
    $rootScope.highlighted_entry = entry

    entry_css_selector = "#feed-entries a[data-entry-id=#{entry.id}]"

    # Add CSS class "highlighted-entry" only to currently highlighted entry
    $(entry_css_selector).addClass 'highlighted-entry'
    $('a[data-entry-id]').not(entry_css_selector).removeClass 'highlighted-entry'

    # Make caret visible only for the currently highlighted entry
    $("#{entry_css_selector} i.current-entry").show()
    $('i.current-entry').not("#{entry_css_selector} i.current-entry").hide()

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
        set $rootScope.entries[index + 1]

    #---------------------------------------------
    # Highlight the previous entry (above current one)
    #---------------------------------------------
    previous: ->
      index = $rootScope.entries.indexOf $rootScope.highlighted_entry
      if index > 0 && index < $rootScope.entries.length
        set $rootScope.entries[index - 1]

  return service
]