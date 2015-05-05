########################################################
# AngularJS service for the currently highlighted entry.
########################################################

angular.module('feedbunch').service 'highlightedEntrySvc',
['$rootScope',
($rootScope)->

  #---------------------------------------------
  # Set the currently highlighted entry
  #---------------------------------------------
  set: (entry)->
    $rootScope.highlighted_entry = entry

  #---------------------------------------------
  # Highlight the next entry (below current one)
  #---------------------------------------------
  next: ->
    index = $rootScope.entries.indexOf $rootScope.highlighted_entry
    if index >= 0 && index < ($rootScope.entries.length - 1)
      $rootScope.highlighted_entry = $rootScope.entries[index + 1]

  #---------------------------------------------
  # Highlight the previous entry (above current one)
  #---------------------------------------------
  previous: ->
    index = $rootScope.entries.indexOf $rootScope.highlighted_entry
    if index > 0 && index < $rootScope.entries.length
      $rootScope.highlighted_entry = $rootScope.entries[index - 1]
]