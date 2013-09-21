########################################################
# AngularJS controller file
########################################################

angular.module('feedbunch').controller 'DeviseCtrl',
['$scope', '$timeout', ($scope, $timeout)->

  # If there is a devise alert, show it and close it after 5 seconds
  $scope.error_devise = true
  $timeout ->
    $scope.error_devise = false
  , 5000
]