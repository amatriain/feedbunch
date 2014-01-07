########################################################
# AngularJS main application file
########################################################

module = angular.module 'feedbunch', ['infinite-scroll', 'ngSanitize']

module.config ["$httpProvider", ($httpProvider)->
  # Configure $http service to send the CSRF-prevention token, otherwise POST, DELETE etc requests will be rejected
  $httpProvider.defaults.headers.common['X-CSRF-Token'] = $('meta[name=csrf-token]').attr('content')

  # Redirect user to /login if any AJAX request is responded with a 401 status (unauthorized).
  # Otherwise pass on errors to the individual error handler callback.
  $httpProvider.interceptors.push ['$window', '$q', ($window, $q)->
    'responseError': (rejection)->
      if rejection.status == 401
        $window.location.href = '/login'
      else
        return $q.reject rejection
  ]
]