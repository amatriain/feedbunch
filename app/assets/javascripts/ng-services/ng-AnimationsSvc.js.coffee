########################################################
# AngularJS service to help with animations.
########################################################

angular.module('feedbunch').service 'animationsSvc',
['$rootScope',
($rootScope)->

  #--------------------------------------------
  # PRIVATE FUNCTION - Add a CSS class that sets identifies entry as open, for testing.
  # Also set explictly height to 'auto' (setting the CSS class alone does not override the explicitly set
  # height otherwise).
  # This way if images in the entry are lazy-loaded after the open animation is finished,
  # the entry height will adjust instantaneously.
  #--------------------------------------------
  add_open_class = ->
    $(this).addClass('entry_open').css 'height', 'auto'

  #--------------------------------------------
  # PRIVATE FUNCTION - Add a CSS class that sets entry height to 'auto'.
  # This way if images in the entry are lazy-loaded after the open animation is finished,
  # the entry height will adjust instantaneously.
  #--------------------------------------------
  remove_open_class = ->
    $(this).removeClass 'entry_open'

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
        .animate {height: height_auto, 'padding-top': 15, 'padding-bottom': 15}, 300, 'swing', add_open_class

    #---------------------------------------------
    # Animate closing an entry, by transitioning its height from its current value to zero
    #---------------------------------------------
    close_entry: (entry)->
      $("#entry-#{entry.id}-summary")
        .animate {height: 0, 'padding-top': 0, 'padding-bottom': 0}, 300, 'swing', remove_open_class

  return service
]