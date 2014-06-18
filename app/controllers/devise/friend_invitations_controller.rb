##
# Customized version of Devise::InvitationsController.
# It has been customized to better work with AJAX requests.

class Devise::FriendInvitationsController < Devise::InvitationsController

  respond_to :json, only: [:create]
  respond_to :html, only: [:edit, :update, :destroy]

  prepend_before_filter :authenticate_inviter!, :only => [:create]
  prepend_before_filter :has_invitations_left?, :only => [:create]
  prepend_before_filter :require_no_authentication, :only => [:edit, :update, :destroy]
  prepend_before_filter :resource_from_invitation_token, :only => [:edit, :destroy]
  helper_method :after_sign_in_path_for

  ##
  # Send an invitation email to the passed email address.
  def create
    # TODO after beta stage remove this to allow anyone to invite friends
    if !current_inviter.admin
      head status: 403
      return
    end

    # Create record for the invited user
    @invited_user = invite_user
    # If the created user is invalid, this will raise an error
    @invited_user.save!
    Rails.logger.info "User #{current_inviter.id} - #{current_inviter.email} sent invitation to join Feedbunch to user #{@invited_user.id} - #{@invited_user.email}"
    head status: :ok
  rescue => e
    handle_error e
  end

  # GET /resource/invitation/accept?invitation_token=abcdef
  def edit
    resource.invitation_token = params[:invitation_token]
    render :edit
  end

  # PUT /resource/invitation
  def update
    self.resource = accept_resource

    if resource.errors.empty?
      yield resource if block_given?
      flash_message = resource.active_for_authentication? ? :updated : :updated_not_active
      set_flash_message :notice, flash_message
      sign_in(resource_name, resource)
      respond_with resource, :location => after_accept_path_for(resource)
    else
      respond_with_navigational(resource){ render :edit }
    end
  end

  # GET /resource/invitation/remove?invitation_token=abcdef
  def destroy
    resource.destroy
    set_flash_message :notice, :invitation_removed
    redirect_to after_sign_out_path_for(resource_name)
  end

  protected

  def invite_user
    invitation_params = {email: friend_invitation_params[:email],
                         name: friend_invitation_params[:email],
                         locale: current_inviter.locale,
                         timezone: current_inviter.timezone}
    User.invite! invitation_params, current_inviter
  end

  def accept_resource
    resource_class.accept_invitation!(update_resource_params)
  end

  def current_inviter
    authenticate_inviter!
  end

  def has_invitations_left?
    unless current_inviter.nil? || current_inviter.has_invitations_left?
      Rails.logger.warn "User #{current_inviter.id} - #{current_inviter.email} tried to send an invitation, but has no invitations left"
      head status: 400
      return
    end
  end

  def resource_from_invitation_token
    unless params[:invitation_token] && self.resource = resource_class.find_by_invitation_token(params[:invitation_token], true)
      set_flash_message(:alert, :invitation_token_invalid)
      redirect_to after_sign_out_path_for(resource_name)
    end
  end

  def update_resource_params
    devise_parameter_sanitizer.sanitize(:accept_invitation)
  end

  def friend_invitation_params
    params.require(:user).permit(:email)
  end
end