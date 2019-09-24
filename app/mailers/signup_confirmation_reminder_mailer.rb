# frozen_string_literal: true

class SignupConfirmationReminderMailer < ActionMailer::Base
  default from: "\"FeedBunch\" <#{Feedbunch::Application.config.admin_email}>"

  ##
  # Send an email to remind a signed up user that he stil hasn't confirmed his email address.
  #
  # Receives as arguments:
  # - the user who has done the export

  def reminder_email(user)
    @user = user
    I18n.with_locale user.locale do
      mail to: @user.email
    end
  end

end
