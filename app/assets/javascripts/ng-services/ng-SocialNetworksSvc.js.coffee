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

  #---------------------------------------------
  # Share an entry on Google+
  #---------------------------------------------
  share_gplus_entry: (entry)->
    window.open "https://plus.google.com/share?url=#{entry.url}",'', 'menubar=no,toolbar=no,resizable=yes,scrollbars=yes,height=600,width=600'
]