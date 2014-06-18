########################################################
# AngularJS service to manage sending invitations to join Feedbunch to friends
########################################################

angular.module('feedbunch').service 'invitationsSvc',
['$http', 'timerFlagSvc',
($http, timerFlagSvc)->

  #---------------------------------------------
  # Send an invitation to join Feedbunch to a friend
  #---------------------------------------------
  send_invitation: (email)->
    # Email to send the invitation to
    if email
      $http.post('/invitation.json', user: {email: email})
      .success (data)->
        timerFlagSvc.start 'success_invite_friend'
      .error (data, status)->
        # Show alert
        if status == 403
          timerFlagSvc.start 'invite_friend_unauthorized'
        else if status == 409
          timerFlagSvc.start 'error_invited_user_exists'
        else if status == 400
          timerFlagSvc.start 'no_invitations_left'
        else
          timerFlagSvc.start 'error_sending_invitation'

]