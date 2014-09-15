########################################################
# AngularJS service to show application tours
########################################################

angular.module('feedbunch').service 'tourSvc',
['$http', ($http)->

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

]