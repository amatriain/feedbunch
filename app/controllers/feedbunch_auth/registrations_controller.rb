##
# Customized version of Devise::RegistrationsController.
#
# Before creating an account (RegistrationsController#create), it checks if the passed email is already in the db
# associated with a user that was sent an invitation email but never accepted it. In this case the already-existing
# user is destroyed before yielding to the default Devise controller. This allows users who received an invitation
# email but never accepted it to sign up normally.
#
# Before accepting an account deletion (RegistrationsController#destroy method), it
# validates that the user-submitted password is correct. Only if the password is correct
# RegistrationsController#destroy is invoked to actually delete the account.

class FeedbunchAuth::RegistrationsController < Devise::RegistrationsController

  before_filter :authenticate_user!, except: [:create]

  respond_to :html

  ##
  # Create a new user account.
  #
  # The submitted email is checked to see if there is a user account already created with that email address, and
  # in this case if the account was created because of an invitation sent but not yet accepted. If so,
  # the account is deleted before performing the usual Devise signup operations.
  #
  # This allows users who have been invited to sign up normally instead of accepting the invitation. This overrides
  # the default Devise behavior, which is not to allow signup for invited users (an "email has been taken" error is
  # returned by default, which is not the behavior we desire).

  def create

    if User.exists? email: params[:user][:email]
      user = User.find_by_email params[:user][:email]
      if user.invited_to_sign_up?
        Rails.logger.warn "User #{user.email} was invited but instead of accepting the invitation is signing up normally. Destroying old user record before signup."
        user.destroy
      end
    end

    super
  end

  ##
  # Delete a user's profile.
  # A password parameter must be submitted. The method validates that the submitted password
  # is actually the user's password, otherwise an error is returned.
  def destroy
    Rails.logger.warn "User #{current_user.id} - #{current_user.email} has requested account deletion"
    password = profiles_controller_destroy_params[:password]
    if current_user.valid_password? password
      Rails.logger.warn "User #{current_user.id} - #{current_user.email} provided correct password for account deletion"
      current_user.delete_profile
      sign_out
      flash[:notice] = t 'devise.registrations.destroyed'
      redirect_to root_path
    else
      Rails.logger.error "User #{current_user.id} - #{current_user.email} provided wrong password for account deletion"
      flash[:alert] = t 'errors.messages.invalid_password'
      redirect_to edit_user_registration_path
    end
  end



  private

  def profiles_controller_destroy_params
    params.require(:delete_user_registration).permit(:password)
  end
end