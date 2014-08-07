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
  # PRIVATE FUNCTION - Open a dropdown menu.
  # Receives as arguments:
  # - jquery object of the menu wrapper (normally a li with class .dropdown)
  # - jquery object of the link that toggles the menu
  # - namespace to apply to the event handler that will be created to close the menu if user clicks outside it.
  # It should be a namespaced "click" event, like "click.mynamespace"
  #--------------------------------------------
  open_menu = (menu_wrapper, menu_link, event_namespace)->
    menu_wrapper.addClass 'open'
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

    # If user clicks anywhere outside the menu link, close it
    $(document).on event_namespace, (event)->
      if $(event.target).closest(menu_link).length == 0
        close_menu menu_wrapper, menu_link, event_namespace
      return true

  #--------------------------------------------
  # PRIVATE FUNCTION - Close a dropdown menu.
  # Receives as arguments:
  # - jquery object of the menu wrapper (normally a li with class .dropdown)
  # - jquery object of the link that toggles the menu
  # - namespace to apply to the event handler that will be created to close the menu if user clicks outside it.
  # It should be a namespaced "click" event, like "click.mynamespace"
  #--------------------------------------------
  close_menu = (menu_wrapper, menu_link, event_namespace)->
    menu_wrapper.removeClass 'open'
    menu = menu_link.siblings '.dropdown-menu'

    # Set height back to 0px and animate the transition to its final height
    menu.velocity {height: 0, 'padding-top': 0, 'padding-bottom': 0},
      {duration: 200, easing: 'swing'}

    # Remove the handler that closes the menu if user clicks outside it.
    # It is no longer necessary now that menu is closed, and having too many handlers hurts performance
    $(document).off event_namespace

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
    # Animate toggling (open/close) the feeds management menu
    #---------------------------------------------
    toggle_feeds_menu: ->
      menu_wrapper = $('#feed-dropdown')
      menu_link = $('#feeds-management')
      event_namespace = 'click.outside_feeds_menu'

      if menu_wrapper.hasClass 'open'
        close_menu menu_wrapper, menu_link, event_namespace
      else
        open_menu menu_wrapper, menu_link, event_namespace

    #---------------------------------------------
    # Animate toggling (open/close) the folders management menu
    #---------------------------------------------
    toggle_folders_menu: ->
      menu_wrapper = $('#folder-management-dropdown')
      menu_link = $('#folder-management')
      event_namespace = 'click.outside_folders_menu'

      if menu_wrapper.hasClass 'open'
        close_menu menu_wrapper, menu_link, event_namespace
      else
        open_menu menu_wrapper, menu_link, event_namespace

    #---------------------------------------------
    # Animate toggling (open/close) the folders management menu
    #---------------------------------------------
    toggle_user_menu: ->
      menu_wrapper = $('#user-dropdown')
      menu_link = $('#user-management')
      event_namespace = 'click.outside_user_menu'

      if menu_wrapper.hasClass 'open'
        close_menu menu_wrapper, menu_link, event_namespace
      else
        open_menu menu_wrapper, menu_link, event_namespace

    #---------------------------------------------
    # Animate toggling (open/close) the folders management menu.
    # Receives the entry as argument.
    #---------------------------------------------
    toggle_entry_social_menu: (entry)->
      menu_wrapper = $("#entry-#{entry.id}-social-menu")
      menu_link = $("#entry-#{entry.id}-social")
      event_namespace = 'click.outside_social_menu'

      if menu_wrapper.hasClass 'open'
        close_menu menu_wrapper, menu_link, event_namespace
      else
        open_menu menu_wrapper, menu_link, event_namespace

  return service
]