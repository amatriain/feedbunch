########################################################
# AngularJS filter to correctly display numerical badges.
# Returns the passed argument unless it is a number >999, in
# which case it returns "999+"
########################################################

angular.module('feedbunch').filter 'numberBadgeFltr',
[->
  return (input)->
    if input > 999
      return "999+"
    else
      return input
]