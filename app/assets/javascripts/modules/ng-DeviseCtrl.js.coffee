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

  # If there is a rails alert, show it and close it after 5 seconds
  $scope.error_rails = true
  $timeout ->
    $scope.error_rails = false
  , 5000
]