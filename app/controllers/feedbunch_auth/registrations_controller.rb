##
# Customized version of Devise::RegistrationsController.
#
# Before accepting an account deletion (RegistrationsController#destroy method), it
# validates that the user-submitted password is correct. Only if the password is correct
# RegistrationsController#destroy is invoked to actually delete the account.

class FeedbunchAuth::RegistrationsController < Devise::RegistrationsController

  before_action :authenticate_user!, except: [:create]

  respond_to :html

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



  protected

  ##
  # Redirect user to a static page after signup

  def after_inactive_sign_up_path_for(resource)
    signup_success_path
  end

  def profiles_controller_destroy_params
    params.require(:delete_user_registration).permit(:password)
  end
end