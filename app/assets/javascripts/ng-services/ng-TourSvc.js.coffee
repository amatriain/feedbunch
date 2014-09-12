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
      id: 'main-tour',
      showCloseButton: true,
      showPrevButton: true,
      showNextButton: true,
      steps: [
        {
          title: 'Sidebar',
          target: '#all-feeds',
          placement: 'right',
          content: '<p>You will see your subscribed feeds here.</p>' +
                    '<ul>' +
                    '<li>Click on a feed to see its entries.</li>' +
                    '<li>Click on <strong><em>All subscriptions</em></strong> to see entries from all feeds.</li>' +
                    '<li>Click on <strong><em>Start</em></strong> to see the start page again.</li>' +
                    '</ul>'
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