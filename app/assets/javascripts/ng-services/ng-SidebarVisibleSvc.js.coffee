########################################################
# AngularJS service to manage the boolean flag that controls the visibility of the sidebar and, by extension
# of the entries list (when the sidebar is visible the entries list is not).
# This only has effect under the Bootstrap xs breakpoint; for viewports wider than that both the sidebar and
# the entries list are visible simultaneously.
########################################################

angular.module('feedbunch').service 'sidebarVisibleSvc',
['$rootScope', ($rootScope)->

  toggle: ->
    if $rootScope.sidebar_visible?
      $rootScope.sidebar_visible = !$rootScope.sidebar_visible
    else
      $rootScope.sidebar_visible = true
]