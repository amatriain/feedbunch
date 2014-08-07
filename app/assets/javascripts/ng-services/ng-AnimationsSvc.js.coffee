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
  add_entry_open_class = ->
    $(this).addClass('entry_open').css 'height', 'auto'

  #--------------------------------------------
  # PRIVATE FUNCTION - Add a CSS class that sets entry height to 'auto'.
  # This way if images in the entry are lazy-loaded after the open animation is finished,
  # the entry height will adjust instantaneously.
  #--------------------------------------------
  remove_entry_open_class = ->
    $(this).removeClass 'entry_open'

  #--------------------------------------------
  # PRIVATE FUNCTION - Open a dropdown menu. Receives the menu link as argument.
  #--------------------------------------------
  open_menu = (menu_link)->
    menu_link.parent().addClass 'open'
    menu = menu_link.siblings '.dropdown-menu'

    # Make menu height 'auto' temporarily to measure its final height
    padding_top = 5
    padding_bottom = 5
    menu.css('height', 'auto')
    height_auto = menu.outerHeight() + padding_top + padding_bottom

    # Set height back to 0px and animate the transition to its final height
    menu
      .css('height', '0')
      .velocity {height: height_auto, 'padding-top': padding_top, 'padding-bottom': padding_bottom},
        {duration: 200, easing: 'swing'}

    # If user clicks anywhere outside the menu, close it
    $(document).on 'click', (event)->
      menu_parent = $(event.target).closest '.dropdown'
      if  menu_parent.length <= 0 || (menu_parent.length > 0 && !menu_parent.is menu_link.parent())
        close_menu menu_link
      return true


  #--------------------------------------------
  # PRIVATE FUNCTION - Close a dropdown menu. Receives the menu link as argument.
  #--------------------------------------------
  close_menu = (menu_link)->
    menu_link.parent().removeClass 'open'
    menu = menu_link.siblings '.dropdown-menu'

    # Set height back to 0px and animate the transition to its final height
    menu.velocity {height: 0, 'padding-top': 0, 'padding-bottom': 0},
      {duration: 200, easing: 'swing'}

  service =

    #---------------------------------------------
    # Animate opening an entry, by transitioning its height from zero to its final value.
    #---------------------------------------------
    open_entry: (entry)->
      entry_summary = $("#entry-#{entry.id}-summary")

      # Temporarily make entry content visible (height > 0) to measure its height
      padding_top = 15
      padding_bottom = 15
      entry_summary.css('height', 'auto')
      height_auto = entry_summary.outerHeight() + padding_top + padding_bottom

      # Set height back to 0px and animate the transition to its final height
      # After finishing opening animation, scroll to show as much of the entry content as possible.
      # We leave an offset so that part of the entry above is still visible under the navbar.
      topOffset = -120
      entry_summary
        .css('height', '0')
        .velocity({height: height_auto, 'padding-top': padding_top, 'padding-bottom': padding_bottom},
          {duration: 300, easing: 'swing', complete: add_entry_open_class})
        .velocity 'scroll', {offset: topOffset, duration: 300}

    #---------------------------------------------
    # Animate closing an entry, by transitioning its height from its current value to zero
    #---------------------------------------------
    close_entry: (entry)->
      $("#entry-#{entry.id}-summary")
        .velocity {height: 0, 'padding-top': 0, 'padding-bottom': 0},
          {duration: 300, easing: 'swing', complete: remove_entry_open_class}

    #---------------------------------------------
    # Animate opening a dropdown menu. Receives the click event as argument.
    #---------------------------------------------
    toggle_menu: (event)->
      menu_link = $(event.target)
      if menu_link.parent().hasClass 'open'
        close_menu menu_link
      else
        open_menu menu_link

  return service
]