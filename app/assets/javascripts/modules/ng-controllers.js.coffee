########################################################
# AngularJS controllers file
########################################################

angular.module('feedbunch').controller 'FoldersCtrl', ($scope, $http)->

  $http.get('/folders.json').success (data)->
    $scope.folders = data

  $http.get('/feeds.json').success (data)->
    $scope.feeds = data
