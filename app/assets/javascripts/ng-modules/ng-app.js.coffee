########################################################
# AngularJS main application file
########################################################

module = angular.module 'feedbunch', ['infinite-scroll', 'ngSanitize', 'ngTouch']

module.config ["$httpProvider", "$compileProvider", ($httpProvider, $compileProvider)->
  # Configure $http service to send the CSRF-prevention token expected by rails,
  # otherwise POST, DELETE etc requests will be rejected.
  # Angularjs reads the CSRF token from the "XSRF-TOKEN" cookie by default. It sends it back in the
  # X-XSRF-TOKEN header by default, but we have to change it to X-CSRF-Token which is the header expected
  # by the Rails backend.
  $httpProvider.defaults.xsrfHeaderName = 'X-CSRF-Token'

  # Redirect user to /login if any AJAX request is responded with a 401 status (unauthorized).
  # Otherwise pass on errors to the individual error handler callback.
  $httpProvider.interceptors.push ['$window', '$q', ($window, $q)->
    'responseError': (rejection)->
      if rejection.status == 401
        $window.location.href = '/login'
      else
        return $q.reject rejection
  ]
  
  # Disable debug info from app. This removes ng-scope and ng-isolated-scope classes needed by some
  # debuggers, along with the performance hit of adding and removing these clases dynamically.
  $compileProvider.debugInfoEnabled false
]
