##
# Customized version of Devise::InvitationsController.
# It has been customized to better work with AJAX requests. It also can resend invitation emails without generating
# a new invitation token.

class FeedbunchAuth::InvitationsController < Devise::InvitationsController
  respond_to :json, only: [:create]

  prepend_before_filter :authenticate_inviter!, :only => [:create]
  prepend_before_filter :has_invitations_left?, :only => [:create]

  ##
  # Send an invitation email to the passed email address.

  def create
    invited_email = friend_invitation_params[:email]

    # Check if user already exists
    if User.exists? email: invited_email
      user = User.find_by_email invited_email
      if user.invited_to_sign_up?
        # If user was invited and is awaiting confirmation, the invitation email will be resent.
        resend_invitation_email user
        head status: 202
        return
      else
        # If user already exists (not through an invitation), it cannot be sent an invitation.
        Rails.logger.warn "User #{current_inviter.id} - #{current_inviter.email} tried to send invitation to #{invited_email} but a user with that email already exists"
        head status: 409
        return
      end
    end

    # Create record for the invited user
    @invited_user = invite_user invited_email
    # If the created user is invalid, this will raise an error
    @invited_user.save!
    Rails.logger.info "User #{current_inviter.id} - #{current_inviter.email} sent invitation to join FeedBunch to user #{@invited_user.id} - #{@invited_user.email}"
    head status: :ok

  rescue => e
    handle_error e
  end

  protected

  ##
  # After a successful login, a user is redirected to the feeds list

  def after_sign_in_path_for(resource)
    read_path
  end

  ##
  # Create a user invitation.
  #
  # This creates a User instance in unconfirmed state, and sends an invitation email.
  # The new user initially has the same locale and timezone as the inviter, and his username will default to his
  # email address. All these values can be changed after accepting the invitation.
  #
  # Receives as argument:
  # - email of the invited user. The invitation will be sent to this email address.

  def invite_user(email)
    invitation_params = {email: email,
                         name: email,
                         locale: current_inviter.locale,
                         timezone: current_inviter.timezone}
    invited_user = User.invite! invitation_params, current_inviter
    current_inviter.update invitations_count: (current_inviter.invitations_count + 1)

    # Persist the unencrypted invitation token so that it can be reused to resend invitations to the same email address.
    # We need to save in "unencrypted_invitation_token" because "raw_invitation_token" is an instance method that
    # only has value for this User instance, devise_invitable does not persist it in the DB.
    invited_user.update unencrypted_invitation_token: invited_user.raw_invitation_token
    return invited_user
  end

  ##
  # Send again an invitation email for an already invited user.
  # The invitation token is not changed; this means that the "accept" link in this email is exactly the same as the one sent when originally invited.
  # The invitations_count attribute of the inviter is incremented by 1.

  def resend_invitation_email(user)
    Rails.logger.warn "User #{current_inviter.id} - #{current_inviter.email} is resending invitation to #{user.email} that was already invited on #{user.invitation_sent_at}"
    Devise.mailer.invitation_instructions(user, user.unencrypted_invitation_token).deliver_later
    current_inviter.update invitations_count: (current_inviter.invitations_count + 1)
    return
  end

  ##
  # Return the user who is sending the invitation.

  def current_inviter
    authenticate_inviter!
  end

  ##
  # Validate that the user sending the invitation actually has invitations left.
  # If he doesn't, an HTTP 400 is returned and the response chain is aborted.

  def has_invitations_left?
    # Admin users have no invitations limit
    return true if current_inviter.admin

    # If no invitation limit has been set, there are always invitations left
    return true if current_inviter.invitation_limit.nil?

    if current_inviter.invitations_count >= current_inviter.invitation_limit
      Rails.logger.warn "User #{current_inviter.id} - #{current_inviter.email} tried to send an invitation, but has no invitations left"
      head status: 400
      return
    end
  end

  ##
  # Filter the accepted HTTP params, according to Rails 4 Strong Parameters feature.

  def friend_invitation_params
    params.require(:user).permit(:email)
  end
end