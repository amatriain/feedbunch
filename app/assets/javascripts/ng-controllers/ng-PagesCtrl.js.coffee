########################################################
# AngularJS controller file
########################################################

angular.module('feedbunch').controller 'PagesCtrl',
['$scope', 'timerFlagSvc', 'tooltipSvc', 'cookiesSvc', 'animationsSvc', 'formFocusSvc',
($scope, timerFlagSvc, tooltipSvc, cookiesSvc, animationsSvc, formFocusSvc)->

  # If there is a rails alert, show it and close it after 5 seconds
  timerFlagSvc.start 'error_rails'

  # Initialize footer tooltips
  tooltipSvc.footer_tooltips()

  # Initialize tooltip on cookies warning "accept" button
  tooltipSvc.cookies_warning_tooltips()

  # Initialize giving focus to form fields when shown
  formFocusSvc.start()

  #--------------------------------------------
  # Toggle (open/close) the switch locale menu with an animation
  #--------------------------------------------
  $scope.toggle_locale_menu = ->
    animationsSvc.toggle_locale_menu()
    return

  #--------------------------------------------
  # Set a cookie that indicates that the user has accepted cookie use (to comply with EU law).
  #--------------------------------------------
  $scope.accept_cookies = ->
    cookiesSvc.accept_cookies()
    return
]