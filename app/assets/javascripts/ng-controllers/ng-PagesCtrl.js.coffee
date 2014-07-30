########################################################
# AngularJS controller file
########################################################

angular.module('feedbunch').controller 'PagesCtrl',
['timerFlagSvc', 'tooltipSvc',
(timerFlagSvc, tooltipSvc)->

  # If there is a rails alert, show it and close it after 5 seconds
  timerFlagSvc.start 'error_rails'

  # Initialize footer tooltips
  tooltipSvc.footer_tooltips()

  # Initialize tooltip on cookies warning "accept" button
  tooltipSvc.cookies_warning_tooltips()
]