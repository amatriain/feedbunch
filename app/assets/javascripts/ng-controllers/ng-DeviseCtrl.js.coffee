########################################################
# AngularJS controller file
########################################################

angular.module('feedbunch').controller 'DeviseCtrl',
['timerFlagSvc', (timerFlagSvc)->

  # If there is a devise alert, show it and close it after 5 seconds
  timerFlagSvc.start 'error_devise'

  # If there is a rails alert, show it and close it after 5 seconds
  timerFlagSvc.start 'error_rails'
]