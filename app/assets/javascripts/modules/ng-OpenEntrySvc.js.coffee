########################################################
# AngularJS service to set, unset and recover the currently selected folder in the root scope
########################################################

angular.module('feedbunch').service 'openEntrySvc',
['$rootScope', ($rootScope)->

  set: (entry)->
    $rootScope.open_entry = entry

  unset: ->
    $rootScope.open_entry = null

  get: ->
    $rootScope.open_entry
]