########################################################
# AngularJS controllers file
########################################################

angular.module('feedbunch').controller 'FoldersCtrl', ($scope, $http)->
  $http.get('/folders.json').success (data)->
    $scope.folders = data
  $http.get('/feeds.json').success (data)->
    $scope.feeds = data

###

  $scope.folders = [
    {
      id: 'all',
      title: 'All subscriptions',
      path: '/folders/all',
      unread: 12,
      feeds: [
        {
          id: 1,
          title: 'primer feed',
          path: '/feeds/1',
          url: 'http://feed.primero.com',
          folder_id: 1,
          unread: 15
        },
        {
          id: 2,
          title: 'segundo feed',
          path: '/feeds/2',
          url: 'http://feed.segundo.com',
          folder_id: 1,
          unread: 16
        },
        {
          id: 3,
          title: 'tercer feed',
          path: '/feeds/3',
          url: 'http://feed.tercero.com',
          folder_id: 2,
          unread: 17
        },
        {
          id: 4,
          title: 'cuarto feed',
          path: '/feeds/4',
          url: 'http://feed.cuarto.com',
          folder_id: 'none',
          unread: 1
        }
      ]
    },
    {
      id: 1,
      title: 'uno',
      path: '/folders/1',
      unread: 10,
      feeds: [
        {
          id: 1,
          title: 'primer feed',
          path: '/feeds/1',
          url: 'http://feed.primero.com',
          folder_id: 1,
          unread: 15
        },
        {
          id: 2,
          title: 'segundo feed',
          path: '/feeds/2',
          url: 'http://feed.segundo.com',
          folder_id: 1,
          unread: 16
        }
      ]
    },
    {
      id: 2,
      title: 'dos',
      path: '/folders/2',
      unread: 2,
      feeds: [
        {
          id: 3,
          title: 'tercer feed',
          path: '/feeds/3',
          url: 'http://feed.tercero.com',
          folder_id: 2,
          unread: 17
        }
      ]
    }
  ]

###