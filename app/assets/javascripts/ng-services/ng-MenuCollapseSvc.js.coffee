########################################################
# AngularJS service to manage opening and collapsing the app menu in smartphones
########################################################

angular.module('feedbunch').service 'menuCollapseSvc',
['$rootScope', ($rootScope)->

  #---------------------------------------------
  # Enable collapsible behavior on startup
  #---------------------------------------------
  start: ->
    $('.navbar-collapse').collapse(toggle: false)

  #---------------------------------------------
  # Close the collapsible menu
  #---------------------------------------------
  close: ->
    $('.navbar-collapse').collapse 'hide'
]