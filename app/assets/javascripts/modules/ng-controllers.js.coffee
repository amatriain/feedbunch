########################################################
# AngularJS controllers file
########################################################

angular.module('feedbunch').controller 'FoldersCtrl', ['$scope', '$http', ($scope, $http)->

  $http.get('/folders.json').success (data)->
    $scope.folders = data

  $http.get('/feeds.json').success (data)->
    $scope.feeds = data

  $scope.feed_in_folder = (folder)->
    return (feed)->
      if folder.id == 'all'
        return true
      else
        return folder.id == feed.folder_id
]