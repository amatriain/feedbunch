########################################################
# AngularJS main application file
########################################################

module = angular.module 'feedbunch', ['infinite-scroll', 'ngSanitize']

# Configure $http service to send the CSRF-prevention token, otherwise POST, DELETE etc requests will be rejected
module.config ["$httpProvider", ($httpProvider)->
  $httpProvider.defaults.headers.common['X-CSRF-Token'] = $('meta[name=csrf-token]').attr('content')
  $httpProvider.interceptors.push ['$window', '$q', ($window, $q)->
    'responseError': (rejection)->
      if rejection.status == 401
        $window.location.href = '/login'
      else
        return $q.reject rejection
  ]
]