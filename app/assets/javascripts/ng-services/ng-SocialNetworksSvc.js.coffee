########################################################
# AngularJS service to share entries in social networks
########################################################

angular.module('feedbunch').service 'socialNetworksSvc',
['$rootScope'
($rootScope)->

  #---------------------------------------------
  # Share an entry on Facebook
  #---------------------------------------------
  share_facebook_entry: (entry)->
    FB.ui method: 'share', href: entry.url
]