########################################################
# AngularJS controller file
########################################################

angular.module('feedbunch').controller 'PagesCtrl',
['timerFlagSvc', (timerFlagSvc)->

  # If there is a rails alert, show it and close it after 5 seconds
  timerFlagSvc.start 'error_rails'
]