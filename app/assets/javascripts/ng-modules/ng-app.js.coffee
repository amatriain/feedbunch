########################################################
# AngularJS main application file
########################################################

module = angular.module 'feedbunch', []

# Configure $http service to send the CSRF-prevention token, otherwise POST, DELETE etc requests will be rejected
module.config ["$httpProvider", (provider)->
  provider.defaults.headers.common['X-CSRF-Token'] = $('meta[name=csrf-token]').attr('content')
]