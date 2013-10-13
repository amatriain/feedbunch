class DataImportMailer < ActionMailer::Base
  default from: 'info@feedbunch.com'

  ##
  # Send an email when the Import OPML background process is finished successfully

  def import_finished_success_email(user)
    @user = user
    @url = read_url
    mail to: @user.email, subject: 'Your feed subscriptions have been imported into Feedbunch'
  end

  ##
  # Send an email when the Import OPML background process is finished with an error

  def import_finished_error_email(user)
    @user = user
    @url = read_url
    mail to: @user.email, subject: 'There has been an error importing your feed subscriptions into Feedbunch'
  end
end
