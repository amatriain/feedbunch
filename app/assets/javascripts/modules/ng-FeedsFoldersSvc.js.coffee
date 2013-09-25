########################################################
# AngularJS service to load feeds and folders data in the scope
########################################################

angular.module('feedbunch').service 'feedsFoldersSvc',
['$http', ($http)->

  load_data: ($scope)->
    $http.get('/folders.json').success (data)->
      $scope.folders = data

    $http.get('/feeds.json').success (data)->
      $scope.feeds = data
]