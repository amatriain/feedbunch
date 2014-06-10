class OpmlImportMailer < ActionMailer::Base
  default from: "\"Feedbunch\" <#{Feedbunch::Application.config.admin_email}>"

  ##
  # Send an email when the Import OPML background process is finished successfully

  def import_finished_success_email(user)
    @user = user
    @url = read_url locale: user.locale
    I18n.with_locale user.locale do
      mail to: @user.email
    end
  end

  ##
  # Send an email when the Import OPML background process is finished with an error

  def import_finished_error_email(user)
    @user = user
    @url = read_url locale: user.locale
    I18n.with_locale user.locale do
      mail to: @user.email
    end
  end
end
