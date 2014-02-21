########################################################
# AngularJS service to enable tooltips on elements
########################################################

angular.module('feedbunch').service 'tooltipSvc',
['$rootScope', ($rootScope)->

  #---------------------------------------------
  # Enable tooltips on some entry buttons and links
  #---------------------------------------------
  entry_tooltips: (entry)->
    $("#entry-#{entry.id} a[data-toggle='tooltip']").tooltip()

  #---------------------------------------------
  # Enable tooltips on navbar buttons
  #---------------------------------------------
  navbar_tooltips: ->
    $(".navbar .nav.navbar-nav li[data-toggle='tooltip']").tooltip()

  #---------------------------------------------
  # Enable tooltips on the feed title link
  #---------------------------------------------
  feed_title_tooltip: ->
    $("#feed-title a[data-toggle='tooltip']").tooltip()
]