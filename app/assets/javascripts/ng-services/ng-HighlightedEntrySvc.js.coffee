########################################################
# AngularJS service for the currently highlighted entry.
########################################################

angular.module('feedbunch').service 'highlightedEntrySvc',
['$rootScope', 'animationsSvc',
($rootScope, animationsSvc)->

  # Media query to enable highlighting only in screens wider than a tablet's
  md_min_media_query = 'screen and (min-width: 992px)'

  #---------------------------------------------
  # PRIVATE FUNCTION: Set the currently highlighted entry
  #---------------------------------------------
  set = (entry)->
    # Do not enable highlighting in smartphone and tablet-sized screens
    enquire.register md_min_media_query, ->
      $rootScope.highlighted_entry = entry

      entry_link = $("#feed-entries a[data-entry-id=#{entry.id}]")
      # Add CSS class "highlighted-entry" only to currently highlighted entry
      entry_link.addClass 'highlighted-entry'
      $("#feed-entries a[data-entry-id!=#{entry.id}].highlighted-entry").removeClass 'highlighted-entry'

  service =

    #---------------------------------------------
    # Set the first entry in the list as the currently highlighted one
    #---------------------------------------------
    reset: ->
      # Do not enable highlighting in smartphone and tablet-sized screens
      enquire.register md_min_media_query, ->
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
      # Do not enable highlighting in smartphone and tablet-sized screens
      enquire.register md_min_media_query, ->
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
      # Do not enable highlighting in smartphone and tablet-sized screens
      enquire.register md_min_media_query, ->
        index = $rootScope.entries.indexOf $rootScope.highlighted_entry
        if index > 0 && index < $rootScope.entries.length
          previous_entry = $rootScope.entries[index - 1]
          set previous_entry
          # Scroll page so that highlighted entry is visible, if necessary
          animationsSvc.entry_scroll_up previous_entry

  return service
]