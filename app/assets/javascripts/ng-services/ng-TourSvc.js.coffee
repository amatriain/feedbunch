########################################################
# AngularJS service to show application tours
########################################################

angular.module('feedbunch').service 'tourSvc',
['$rootScope', ($rootScope)->

  #---------------------------------------------
  # Show the main application tour.
  #---------------------------------------------
  show_main_tour: ->
    tour =
      id: 'hello-hopscotch',
      showCloseButton: true,
      showPrevButton: true,
      showNextButton: true,
      steps: [
        {
          title: 'My header',
          content: 'This is the header of my page',
          target: '#subscription-stats',
          placement: 'left'
        },
        {
          title: 'My content',
          content: 'Here is where I put my content',
          target: '#start-info img.application-main-icon',
          placement: 'bottom'
        }
      ]

    hopscotch.startTour tour

]