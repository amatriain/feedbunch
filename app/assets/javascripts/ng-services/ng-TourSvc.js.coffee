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
          title: 'Start',
          target: '#subscription-stats',
          placement: 'bottom',
          content: '<p>This is the start page.</p>' +
                    '<p>You can find your usage stats here. Notifications are also shown in this page.</p>'
        },
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
        }
      ]

    hopscotch.startTour tour

]