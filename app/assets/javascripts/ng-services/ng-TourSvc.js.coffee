########################################################
# AngularJS service to show application tours
########################################################

angular.module('feedbunch').service 'tourSvc',
['$rootScope', '$http', '$timeout', 'timerFlagSvc',
($rootScope, $http, $timeout, timerFlagSvc)->

  #--------------------------------------------
  # Media query to show the main app tour only in screens bigger than a smartphone
  #--------------------------------------------
  sm_min_media_query = 'screen and (min-width: 768px)'

  #--------------------------------------------
  # Media query to show the mobile app tour only in smartphone-sized screens
  #--------------------------------------------
  xs_max_media_query = 'screen and (max-width: 768px)'

  #--------------------------------------------
  # PRIVATE FUNCTION: set to false the show_main_tour flag for the current user.
  #--------------------------------------------
  dont_show_main_tour = ->
    $rootScope.show_main_tour = false
    $http.put("/api/user_config.json", user_config: {show_main_tour: 'false'})
    .error (data, status)->
      timerFlagSvc.start 'error_changing_show_tour' if status!=0

  #--------------------------------------------
  # PRIVATE FUNCTION: set to false the show_mobile_tour flag for the current user.
  #--------------------------------------------
  dont_show_mobile_tour = ->
    $rootScope.show_mobile_tour = false
    $http.put("/api/user_config.json", user_config: {show_mobile_tour: 'false'})
    .error (data, status)->
      timerFlagSvc.start 'error_changing_show_tour' if status!=0

  #--------------------------------------------
  # PRIVATE FUNCTION: set to false the show_feed_tour flag for the current user.
  #--------------------------------------------
  dont_show_feed_tour = ->
    $rootScope.show_feed_tour = false
    $http.put("/api/user_config.json", user_config: {show_feed_tour: 'false'})
    .error (data, status)->
      timerFlagSvc.start 'error_changing_show_tour' if status!=0

  #--------------------------------------------
  # PRIVATE FUNCTION: set to false the show_entry_tour flag for the current user.
  #--------------------------------------------
  dont_show_entry_tour = ->
    $rootScope.show_entry_tour = false
    $http.put("/api/user_config.json", user_config: {show_entry_tour: 'false'})
    .error (data, status)->
      timerFlagSvc.start 'error_changing_show_tour' if status!=0

  #--------------------------------------------
  # PRIVATE FUNCTION: set to false the show_kb_shortcuts_tour flag for the current user.
  #--------------------------------------------
  dont_show_kb_shortcuts_tour = ->
    $rootScope.show_kb_shortcuts_tour = false
    $http.put("/api/user_config.json", user_config: {show_kb_shortcuts_tour: 'false'})
    .error (data, status)->
      timerFlagSvc.start 'error_changing_show_tour' if status!=0

  #---------------------------------------------
  # PRIVATE FUNCTION: show the keyboard shortcuts application tour.
  #---------------------------------------------
  show_kb_shortcuts_tour = ->
    # If main tour is completed, kb shortcuts tour is shown as soon as page is loaded (unless already completed too)
    if !$rootScope.show_main_tour && $rootScope.show_kb_shortcuts_tour
      # The keyboards shortcuts tour is only shown in screens bigger than a smartphone
      enquire.register sm_min_media_query, ->
        $http.get("/api/tours/kb_shortcuts.json")
        .success (data)->
          tour =
            id: 'kb_shortcuts-tour',
            showCloseButton: true,
            showPrevButton: false,
            showNextButton: true,
            onEnd: dont_show_kb_shortcuts_tour,
            onClose: dont_show_kb_shortcuts_tour,
            i18n: data['i18n'],
            steps: data['steps']
          hopscotch.startTour tour
        .error (data, status)->
          timerFlagSvc.start 'error_loading_tour' if status!=0

  #--------------------------------------------
  # PRIVATE FUNCTION: at the end of main tour, mark show_main_tour flag to false so it's not shown again; and if the
  # show_kb_shortcuts_flag is set to true, show the keyboard shortcuts tour
  #--------------------------------------------
  main_tour_end = ->
    dont_show_main_tour()
    show_kb_shortcuts_tour() if $rootScope.show_kb_shortcuts_tour

  service =
    #---------------------------------------------
    # Show the main application tour.
    #---------------------------------------------
    show_main_tour: ->
      # Show the main application tour, if the show_main_tour flag is true
      if $rootScope.show_main_tour
        # The main tour is only shown in screens bigger than a smartphone
        enquire.register sm_min_media_query, ->
          $http.get("/api/tours/main.json")
          .success (data)->
            tour =
              id: 'main-tour',
              showCloseButton: true,
              showPrevButton: false,
              showNextButton: true,
              onEnd: main_tour_end,
              onClose: main_tour_end,
              i18n: data['i18n'],
              steps: data['steps']
            hopscotch.startTour tour
          .error (data, status)->
            timerFlagSvc.start 'error_loading_tour' if status!=0

    #---------------------------------------------
    # Show the mobile application tour.
    #---------------------------------------------
    show_mobile_tour: ->
      if $rootScope.show_mobile_tour
        # The mobile tour is only shown in smartphone-sized screens
        enquire.register xs_max_media_query, ->
          $http.get("/api/tours/mobile.json")
          .success (data)->
            tour =
              id: 'mobile-tour',
              showCloseButton: true,
              showPrevButton: false,
              showNextButton: true,
              onEnd: dont_show_mobile_tour,
              onClose: dont_show_mobile_tour,
              i18n: data['i18n'],
              steps: data['steps']
            hopscotch.startTour tour
          .error (data, status)->
            timerFlagSvc.start 'error_loading_tour' if status!=0

    #---------------------------------------------
    # Show the feed application tour.
    #---------------------------------------------
    show_feed_tour: ->
      if $rootScope.show_feed_tour
        # The feed tour is only shown in screens bigger than a smartphone
        enquire.register sm_min_media_query, ->
          $http.get("/api/tours/feed.json")
          .success (data)->
            tour =
              id: 'feed-tour',
              showCloseButton: true,
              showPrevButton: false,
              showNextButton: true,
              onEnd: dont_show_feed_tour,
              onClose: dont_show_feed_tour,
              i18n: data['i18n'],
              steps: data['steps']
            hopscotch.startTour tour
          .error (data, status)->
            timerFlagSvc.start 'error_loading_tour' if status!=0

    #---------------------------------------------
    # Show the entry application tour.
    #---------------------------------------------
    show_entry_tour: ->
      if $rootScope.show_entry_tour
        $http.get("/api/tours/entry.json")
        .success (data)->
          tour =
            id: 'entry-tour',
            showCloseButton: true,
            showPrevButton: false,
            showNextButton: true,
            onEnd: dont_show_entry_tour,
            onClose: dont_show_entry_tour,
            i18n: data['i18n'],
            steps: data['steps']
          # Show entry tour after a 600ms delay, to give entry open/autoscroll
          # animation time to finish.
          $timeout ->
            hopscotch.startTour tour
          , 600

        .error (data, status)->
          timerFlagSvc.start 'error_loading_tour' if status!=0

    #---------------------------------------------
    # Show the keyboard shortcuts application tour.
    #---------------------------------------------
    show_kb_shortcuts_tour: show_kb_shortcuts_tour

    #---------------------------------------------
    # Reset all application tours, so that they are shown again from the beginning.
    #---------------------------------------------
    reset_tours: ->
      $rootScope.show_main_tour = true
      $rootScope.show_mobile_tour = true
      $rootScope.show_feed_tour = true
      $rootScope.show_entry_tour = true
      $rootScope.show_kb_shortcuts_tour = true
      $http.put "/api/user_config.json",
        user_config:
          show_main_tour: 'true',
          show_mobile_tour: 'true',
          show_feed_tour: 'true',
          show_entry_tour: 'true',
          show_kb_shortcuts_tour: 'true'
      .success (data)->
        timerFlagSvc.start 'success_reset_tours'
      .error (data, status)->
        timerFlagSvc.start 'error_changing_show_tour' if status!=0

  return service

]