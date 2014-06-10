class OpmlExportMailer < ActionMailer::Base
  default from: Feedbunch::Application.config.admin_email

  ##
  # Send an email when the Export OPML background process is finished successfully.
  # The OPML file is attached to the email.
  #
  # Receives as arguments:
  # - the user who has done the export
  # - the filename of the opml, for the attachment
  # - a string with the OPML document

  def export_finished_success_email(user, filename, opml)
    @user = user
    @url = read_url locale: user.locale
    attachments[filename] = opml
    I18n.with_locale user.locale do
      mail to: @user.email
    end
  end

  ##
  # Send an email when the Export OPML background process is finished with an error.

  def export_finished_error_email(user)
    @user = user
    @url = read_url locale: user.locale
    I18n.with_locale user.locale do
      mail to: @user.email
    end
  end
end
