########################################################
# AngularJS service to manage the anti-CSRF token that must be sent
# along with Ajax calls.
########################################################

angular.module('feedbunch').service 'csrfTokenSvc',
['$rootScope', ($rootScope)->

  #---------------------------------------------
  # Read the token set by Rails in the meta tag with name="csrf-token", and return it.
  #---------------------------------------------
  get_token: ->
    token = $('meta[name="csrf-token"]').attr 'content'
    return token
]