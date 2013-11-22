########################################################
# AngularJS service to set, unset and recover currently opened entries in the root scope.
########################################################

angular.module('feedbunch').service 'openEntrySvc',
['$rootScope', '$location', '$anchorScroll',
($rootScope, $location, $anchorScroll)->

  set: (entry)->
    $rootScope.open_entries = [entry]
    # Scroll so that the entry link is at the top of the viewport, for maximum visibility of
    # the entry body
    $location.hash "entry-#{entry.id}-anchor"
    $anchorScroll()

  unset: ->
    $rootScope.open_entries = []
    $location.hash('')

  get: ->
    if $rootScope.open_entries?.length > 0
      return $rootScope.open_entries[0]
    else
      return null

  is_open: (entry)->
    if $rootScope.open_entries?.length > 0
      return $rootScope.open_entries[0].id==entry.id
    else
      return false
]