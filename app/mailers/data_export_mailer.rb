class DataExportMailer < ActionMailer::Base
  default from: 'info@feedbunch.com'

  ##
  # Send an email when the Export OPML background process is finished successfully

  def export_finished_success_email(user)
    @user = user
    @url = read_url locale: user.locale
    I18n.with_locale user.locale do
      mail to: @user.email
    end
  end

  ##
  # Send an email when the Export OPML background process is finished with an error

  def export_finished_error_email(user)
    @user = user
    @url = read_url locale: user.locale
    I18n.with_locale user.locale do
      mail to: @user.email
    end
  end
end
