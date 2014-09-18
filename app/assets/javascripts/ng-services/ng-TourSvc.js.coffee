########################################################
# AngularJS service to show application tours
########################################################

angular.module('feedbunch').service 'tourSvc',
['$http', 'timerFlagSvc', ($http, timerFlagSvc)->

  #--------------------------------------------
  # Media query to show the main app tour only in screens bigger than a smartphone
  #--------------------------------------------
  sm_min_media_query = 'screen and (min-width: 768px)'

  #--------------------------------------------
  # PRIVATE FUNCTION: set to false the show_main_tour flag for the current user.
  #--------------------------------------------
  dont_show_main_tour = ->
    $http.put("/api/user_config.json", user_config: {show_main_tour: 'false'})
    .error (data, status)->
      timerFlagSvc.start 'error_changing_show_tour' if status!=0

  service =
    #---------------------------------------------
    # Show the main application tour.
    #---------------------------------------------
    show_main_tour: ->
      # The main tour is only shown in screens bigger than a smartphone
      enquire.register sm_min_media_query, ->
        now = new Date()
        $http.get("/api/tours/main.json?time=#{now.getTime()}")
        .success (data)->
          tour =
            id: 'main-tour',
            showCloseButton: true,
            showPrevButton: true,
            showNextButton: true,
            onEnd: dont_show_main_tour,
            onClose: dont_show_main_tour,
            i18n: data['i18n'],
            steps: data['steps']
          hopscotch.startTour tour
        .error (data, status)->
          timerFlagSvc.start 'error_loading_tour' if status!=0

  return service

]