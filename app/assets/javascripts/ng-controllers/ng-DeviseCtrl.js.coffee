########################################################
# AngularJS controller file
########################################################

angular.module('feedbunch').controller 'DeviseCtrl',
['$scope', '$window', 'timerFlagSvc', 'sidebarVisibleSvc', 'tooltipSvc',
($scope, $window, timerFlagSvc, sidebarVisibleSvc, tooltipSvc)->

  #--------------------------------------------
  # APPLICATION INITIALIZATION
  #--------------------------------------------

  # The top-left navbar button in smarthpones will be a link to the read view
  sidebarVisibleSvc.set false

  # If there is a devise alert, show it and close it after 5 seconds
  timerFlagSvc.start 'error_devise'

  # If there is a rails alert, show it and close it after 5 seconds
  timerFlagSvc.start 'error_rails'

  # Initialize footer tooltips
  tooltipSvc.footer_tooltips()

  #--------------------------------------------
  # When clicking on the top-left navbar button (only visible in smartphone-sized viewports),
  # go to the read view, with the sidebar visible by default
  #--------------------------------------------
  $scope.toggle_sidebar_visible = ->
    $window.location.href = '/read'
    return
]