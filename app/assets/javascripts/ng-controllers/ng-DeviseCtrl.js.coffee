########################################################
# AngularJS controller file
########################################################

angular.module('feedbunch').controller 'DeviseCtrl',
['$scope', '$window', 'timerFlagSvc', 'sidebarVisibleSvc', 'tooltipSvc', 'invitationsSvc', 'cookiesSvc',
'animationsSvc',
($scope, $window, timerFlagSvc, sidebarVisibleSvc, tooltipSvc, invitationsSvc, cookiesSvc,
animationsSvc)->

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

  # Initialize tooltip on cookies warning "accept" button
  tooltipSvc.cookies_warning_tooltips()

  #--------------------------------------------
  # When clicking on the top-left navbar button (only visible in smartphone-sized viewports),
  # go to the read view, with the sidebar visible by default
  #--------------------------------------------
  $scope.toggle_sidebar_visible = ->
    $window.location.href = '/read'
    return

  #--------------------------------------------
  # Send a friend an invitation to join Feedbunch
  #--------------------------------------------
  $scope.send_invitation = ->
    $("#invite-friend-popup").modal 'hide'
    invitationsSvc.send_invitation $scope.invitation_email
    $scope.invitation_email = null
    return

  #--------------------------------------------
  # Toggle (open/close) user menu with an animation
  #--------------------------------------------
  $scope.toggle_user_menu = ->
    animationsSvc.toggle_user_menu()
    return

  #--------------------------------------------
  # Set a boolean flag in the root scope as false. The flag name must be passed as a string.
  # This is used to hide alerts when clicking on their X button.
  #--------------------------------------------
  $scope.reset_flag = (flag)->
    timerFlagSvc.reset flag
    return

  #--------------------------------------------
  # Set a cookie that indicates that the user has accepted cookie use (to comply with EU law).
  #--------------------------------------------
  $scope.accept_cookies = ->
    cookiesSvc.accept_cookies()
    return
]