########################################################
# AngularJS service to show application tours
########################################################

angular.module('feedbunch').service 'tourSvc',
['$http', 'timerFlagSvc', ($http, timerFlagSvc)->

  #--------------------------------------------
  # PRIVATE FUNCTION: Update show_main_tour flag for the current user with the passed value.
  #--------------------------------------------
  set_show_main_tour = (show_tour)->
    $http.put("/api/user_config.json", user_config: {show_main_tour: show_tour})
    .error (data, status)->
      timerFlagSvc.start 'error_changing_show_tour' if status!=0

  service =
    #---------------------------------------------
    # Show the main application tour.
    #---------------------------------------------
    show_main_tour: ->
      now = new Date()
      $http.get("/api/tour_i18n.json?time=#{now.getTime()}")
      .success (data)->
        tour =
          id: 'main-tour',
          showCloseButton: true,
          showPrevButton: true,
          showNextButton: true,
          i18n: data['i18n']
          steps: data['steps']
        hopscotch.startTour tour
      .error (data, status)->
        timerFlagSvc.start 'error_loading_tour' if status!=0

  return service

]