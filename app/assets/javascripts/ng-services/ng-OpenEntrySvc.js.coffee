########################################################
# AngularJS service to set, unset and recover the currently selected folder in the root scope
########################################################

angular.module('feedbunch').service 'openEntrySvc',
['$rootScope', '$location', '$anchorScroll',
($rootScope, $location, $anchorScroll)->

  set: (entry)->
    $rootScope.open_entry = entry
    # Scroll so that the entry link is at the top of the viewport, for maximum visibility of
    # the entry body
    $location.hash "entry-#{entry.id}-anchor"
    $anchorScroll()

  unset: ->
    $rootScope.open_entry = null
    $location.hash('')

  get: ->
    $rootScope.open_entry
]