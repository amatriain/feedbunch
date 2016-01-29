########################################################
# AngularJS service to help with animations.
########################################################

angular.module('feedbunch').service 'animationsSvc',
['$rootScope', '$timeout',
($rootScope, $timeout)->

  #--------------------------------------------
  # PRIVATE FUNCTION - Add a CSS class that identifies entry as open, for testing.
  # Also set explictly height to 'auto' (setting the CSS class alone does not override the explicitly set
  # height otherwise).
  # This way if images in the entry are lazy-loaded after the open animation is finished,
  # the entry height will adjust instantaneously.
  #--------------------------------------------
  add_entry_open_class = ->
    $(this).addClass('entry_open').css 'height', 'auto'

  #--------------------------------------------
  # PRIVATE FUNCTION - Remove the CSS class that identifies entry as open.
  #--------------------------------------------
  remove_entry_open_class = ->
    $(this).removeClass 'entry_open'

  #--------------------------------------------
  # PRIVATE FUNCTION - Add a CSS class that identifies folder as open.
  # Also set explictly height to 'auto' (setting the CSS class alone does not override the explicitly set
  # height otherwise).
  # This way if feeds are added or removed from the folder, the folder height will adjust instantaneously.
  #--------------------------------------------
  add_folder_open_class = ->
    $(this).addClass('open-folder').css 'height', 'auto'

  #--------------------------------------------
  # PRIVATE FUNCTION - Remove the CSS class that identifies folder as open.
  #--------------------------------------------
  remove_folder_open_class = ->
    $(this).removeClass 'open-folder'

  #--------------------------------------------
  # PRIVATE FUNCTION - Open a dropdown menu.
  # Receives as arguments:
  # - jquery object of the menu wrapper (normally a li or div with class .dropdown)
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
  # - namespace to apply to the event handler that was created to close the menu if user clicks outside it.
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

  #--------------------------------------------
  # Media query to hide sidebar only in smartphone screens
  #--------------------------------------------
  xs_max_media_query = 'screen and (max-width: 768px)'

  service =

    #---------------------------------------------
    # Animate hiding the sidebar if the screens is smartphone-sized.
    #---------------------------------------------
    hide_sidebar: ->
      enquire.register xs_max_media_query, ->
        $('#sidebar-column').velocity {translateX: '-100%'}, {duration: 300, easing: 'swing'}

    #---------------------------------------------
    # Animate showing the sidebar if the screens is smartphone-sized.
    #---------------------------------------------
    show_sidebar: ->
      enquire.register xs_max_media_query, ->
        $('#sidebar-column').velocity {translateX: '0'}, {duration: 300, easing: 'swing'}

    #---------------------------------------------
    # If a sidebar link is not in the viewport, scroll the sidebar down until it is completely inside the viewport.
    # Receives as argument a link object, which has two attributes:
    # - id: if it's a feed or folder link, the ID of the feed or folder. If it's the "Start" link, it has the value 'start'
    # - type: either 'feed' or 'folder' if it's a feed or folder link; null if it's the "Start" link
    #---------------------------------------------
    sidebar_scroll_down: (link_object)->
      if link_object.type == 'feed'
        sidebar_link = $("#folders-list a[data-feed-id=#{link_object.id}]").parent()
      else if link_object.type == 'folder'
        sidebar_link = $("#folders-list #feeds-#{link_object.id} a[data-feed-id='all']").parent()
      else if link_object.id == 'start'
        sidebar_link = $('#start-page').parent()

      if !sidebar_link.next().is ':in-viewport'
        sidebar_column = $('#sidebar-column')
        offset = -1 * (sidebar_column.height() - sidebar_link.outerHeight())
        sidebar_link.velocity 'scroll', {container: sidebar_column, offset: offset, duration: 100}

    #---------------------------------------------
    # If a sidebar link is not in the viewport, scroll the sidebar up until it is completely inside the viewport.
    # Receives as argument a link object, which has two attributes:
    # - id: if it's a feed or folder link, the ID of the feed or folder. If it's the "Start" link, it has the value 'start'
    # - type: either 'feed' or 'folder' if it's a feed or folder link; null if it's the "Start" link
    #---------------------------------------------
    sidebar_scroll_up: (link_object)->
      if link_object.type == 'feed'
        sidebar_link = $("#folders-list a[data-feed-id=#{link_object.id}]").parent()
      else if link_object.type == 'folder'
        sidebar_link = $("#folders-list #feeds-#{link_object.id} a[data-feed-id='all']").parent()
      else if link_object.id == 'start'
        sidebar_link = $('#start-page').parent()

      if !sidebar_link.prev().prev().prev().is ':in-viewport'
        sidebar_column = $('#sidebar-column')
        offset = -8
        sidebar_link.velocity 'scroll', {container: sidebar_column, offset: offset, duration: 100}

    #---------------------------------------------
    # If an entry is not in the viewport, scroll down until it is completely inside the viewport
    #---------------------------------------------
    entry_scroll_down: (entry)->
      entry_link = $("#feed-entries a[data-entry-id=#{entry.id}]")
      if !entry_link.parent().next().is ':in-viewport'
        offset = -1 * ($(window).height() - entry_link.outerHeight())
        entry_link.velocity 'scroll', {offset: offset, duration: 100}

    #---------------------------------------------
    # If an entry is not in the viewport, scroll up until it is completely inside the viewport
    #---------------------------------------------
    entry_scroll_up: (entry)->
      entry_link = $("#feed-entries a[data-entry-id=#{entry.id}]")
      if !entry_link.parent().prev().prev().is ":in-viewport"
        offset = -1 * (3 + $("div.navbar").outerHeight())
        entry_link.velocity 'scroll', {offset: offset, duration: 100}

    #---------------------------------------------
    # Animate opening an entry, by transitioning its height from zero to its final value.
    # Receives as arguments:
    # - entry to be opened
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
        .velocity 'scroll', {offset: topOffset, duration: 250, delay: 50}

    #---------------------------------------------
    # Animate closing an entry, by transitioning its height from its current value to zero.
    # Receives as arguments:
    # - entry to be closed
    #---------------------------------------------
    close_entry: (entry)->
      $("#entry-#{entry.id}-summary")
        .velocity {height: 0, 'padding-top': 0, 'padding-bottom': 0},
          {duration: 300, easing: 'swing', complete: remove_entry_open_class}

    #---------------------------------------------
    # Animate opening a folder, by transitioning its height from zero to its final value.
    #---------------------------------------------
    open_folder: (folder)->
      folder_content = $("#feeds-#{folder.id}.folder-content")
      sidebar_column = $('#sidebar-column')

      # Temporarily make folder content visible (height > 0) to measure its height
      padding_top = 8
      padding_bottom = 8
      folder_content.css('height', 'auto')
      height_auto = folder_content.outerHeight() + padding_top + padding_bottom

      # Set height back to 0px and animate the transition to its final height
      topOffset = -100
      folder_content
      .css('height', '0')
      .velocity {height: height_auto, 'padding-top': padding_top, 'padding-bottom': padding_bottom},
        {duration: 300, easing: 'swing', complete: add_folder_open_class}

      # Rotate folder arrow 90 degrees clockwise (pointing down)
      $("#open-folder-#{folder.id} .folder-arrow")
        .velocity {rotateZ:  '90deg'},
          {duration: 300, easing: 'swing'}

    #---------------------------------------------
    # Animate closing a folder, by transitioning its height from its current value to zero
    #---------------------------------------------
    close_folder: (folder)->
      $("#feeds-#{folder.id}.folder-content")
      .velocity {height: 0, 'padding-top': 0, 'padding-bottom': 0},
        {duration: 300, easing: 'swing', complete: remove_folder_open_class}

      # Rotate folder arrow 90 degrees counter-clockwise (pointing right)
      $("#open-folder-#{folder.id} .folder-arrow")
        .velocity {rotateZ:  '0deg'},
          {duration: 300, easing: 'swing'}

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
    # Animate toggling (open/close) the user menu
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
    # Animate toggling (open/close) an entry social sharing menu.
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

    #---------------------------------------------
    # Animate toggling (open/close) the switch locale menu.
    #---------------------------------------------
    toggle_locale_menu: ->
      menu_wrapper = $('#switch-locale-dropdown')
      menu_link = $('#switch-locale')
      event_namespace = 'click.outside_locale_menu'

      if menu_wrapper.hasClass 'open'
        close_menu menu_wrapper, menu_link, event_namespace
      else
        open_menu menu_wrapper, menu_link, event_namespace

    #---------------------------------------------
    # Animate showing an image in an entry by increasing its opacity from 0 to 1.
    # Receives the jquery object for the image as argument.
    #---------------------------------------------
    show_image: (img)->
      # Give the image height and visibility, to measure its width.
      # It's not yet visible in the page because it has opacity 0
      img.css height: 'auto', visibility: 'visible'

      # center and add display-block to images if wider than 40% of the entries div
      img_width = 100 * img.width() / $('#feed-entries').width()
      if img_width > 40
        img.addClass('center-block').addClass('large-img')
      else
        img.addClass('small-img')

      # Animate increasing the opacity to 1 (this is what makes the user see the image appear)
      img.velocity( {opacity: 1}, {duration: 400, easing: 'linear'})
        .removeClass 'loading'

    #---------------------------------------------
    # Animate showing subscription stats in the start page.
    #---------------------------------------------
    show_stats: ->
      $('#subscription-stats').velocity {opacity: 1}, {duration: 300, easing: 'swing'}

    #---------------------------------------------
    # Temporarily higlight the "Read all" navbar button when clicked.
    #---------------------------------------------
    highlight_read_all_button: ->
      $('#read-all-button')
        .velocity({backgroundColor: '#e7e7e7'}, {duration: 300, easing: 'ease-out'})
        .velocity({backgroundColorAlpha: 0}, {duration: 300, easing: 'ease-in'})

    #---------------------------------------------
    # Temporarily higlight the "Show read" navbar button when clicked.
    #---------------------------------------------
    highlight_show_read_button: ->
      $('#show-read')
        .velocity({backgroundColor: '#e7e7e7'}, {duration: 300, easing: 'ease-out'})
        .velocity({backgroundColorAlpha: 0}, {duration: 300, easing: 'ease-in'})

    #---------------------------------------------
    # Temporarily higlight the "Hide read" navbar button when clicked.
    #---------------------------------------------
    highlight_hide_read_button: ->
      $('#hide-read')
      .velocity({backgroundColor: '#e7e7e7'}, {duration: 300, easing: 'ease-out'})
      .velocity({backgroundColorAlpha: 0}, {duration: 300, easing: 'ease-in'})


  return service
]
