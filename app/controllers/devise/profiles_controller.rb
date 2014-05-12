##
# Customized version of Devise::RegistrationsController.
# The only difference is that before accepting an account deletion (ProfilesController#destroy method), it
# validates that the user-submitted password is correct. Only if the password is correct
# RegistrationsController#destroy is invoked to actually delete the account.

class Devise::ProfilesController < Devise::RegistrationsController

  before_filter :authenticate_user!

  respond_to :html

  ##
  # Delete a user's profile.
  # A password parameter must be submitted. The method validates that the submitted password
  # is actually the user's password, otherwise an error is returned.
  def destroy
    Rails.logger.warn "User #{current_user.id} - #{current_user.email} has requested account deletion"
    password = profiles_controller_params[:password]
    if current_user.valid_password? password
      Rails.logger.warn "User #{current_user.id} - #{current_user.email} provided correct password for account deletion"
      current_user.destroy
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

  def profiles_controller_params
    params.require(:delete_user_registration).permit(:password)
  end
end