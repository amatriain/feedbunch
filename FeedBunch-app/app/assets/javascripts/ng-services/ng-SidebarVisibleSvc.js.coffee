########################################################
# AngularJS service to manage the boolean flag that controls the visibility of the sidebar and, by extension
# of the entries list (when the sidebar is visible the entries list is not).
# This only has effect under the Bootstrap xs breakpoint; for viewports wider than that both the sidebar and
# the entries list are visible simultaneously.
########################################################

angular.module('feedbunch').service 'sidebarVisibleSvc',
['$rootScope', 'animationsSvc', ($rootScope, animationsSvc)->

  #--------------------------------------------
  # Toggle visibility of the sidebar.
  #--------------------------------------------
  toggle: ->
    if $rootScope.sidebar_visible
      animationsSvc.hide_sidebar()
      $rootScope.sidebar_visible = !$rootScope.sidebar_visible
    else
      animationsSvc.show_sidebar()
      $rootScope.sidebar_visible = true

  #--------------------------------------------
  # Set the visibility of the sidebar.
  # Receives as argument a boolean indicating if the sidebar is to become visible
  # (if true) or hidden (if false).
  #--------------------------------------------
  set: (visible)->
    if $.type(visible)=='boolean'
      $rootScope.sidebar_visible = visible
      if visible
        animationsSvc.show_sidebar()
      else
        animationsSvc.hide_sidebar()
]