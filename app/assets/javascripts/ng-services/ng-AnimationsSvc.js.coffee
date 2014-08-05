########################################################
# AngularJS service to help with animations.
########################################################

angular.module('feedbunch').service 'animationsSvc',
['$rootScope',
($rootScope)->

  #--------------------------------------------
  # PRIVATE FUNCTION - Set an entry height to 'auto'.
  # This way if images in the entry are lazy-loaded after the open animation is finished,
  # the entry height will adjust instantaneously.
  #--------------------------------------------
  entry_auto_height = ->
    $(this).css('height', 'auto')

  service =

    #---------------------------------------------
    # Animate opening an entry, by transitioning its height from zero to its final value.
    #---------------------------------------------
    open_entry: (entry)->
      # Temporarily make entry content visible (height > 0) to measure its height
      $("#entry-#{entry.id}-summary").css('height', 'auto')
      height_auto = $("#entry-#{entry.id}-summary").outerHeight()
      # Set height back to 0px and animate the transition to its final height
      $("#entry-#{entry.id}-summary")
        .css('height', '0')
        .animate {height: height_auto, 'padding-top': 15, 'padding-bottom': 15}, 300, 'swing', entry_auto_height

    #---------------------------------------------
    # Animate closing an entry, by transitioning its height from its current value to zero
    #---------------------------------------------
    close_entry: (entry)->
      $("#entry-#{entry.id}-summary")
        .animate {height: 0, 'padding-top': 0, 'padding-bottom': 0}, 300, 'swing'

  return service
]