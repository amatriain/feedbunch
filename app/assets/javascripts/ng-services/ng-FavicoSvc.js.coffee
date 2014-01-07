########################################################
# AngularJS service to change the favicon
########################################################

angular.module('feedbunch').service 'favicoSvc',
['$rootScope', 'unreadCountSvc', ($rootScope, unreadCountSvc)->

  #---------------------------------------------
  # Set the current total unread entries count in the favicon badge.
  #---------------------------------------------
  update_unread_badge: ->
    # Only one Favico object must exist
    if !$rootScope.favico?
      $rootScope.favico = new Favico animation: 'slide', bgColor: '#428BCA'
    unread_count = unreadCountSvc.total_unread_entries()
    $rootScope.favico.badge unread_count

]