##
# Class with methods related to managing data created when a user signs up.

class SignupsManager

  ##
  # Send a reminder email to users who signed up but didn't confirm their email.
  # Two reminders are sent, after that the unconfirmed user is destroyed (see destroy_old_signups below).
  # The time after signup that reminders are sent is configured in these config/application.rb values:
  # - config.first_confirmation_reminder_after
  # - config.second_confirmation_reminder_after

  def self.send_confirmation_reminders
    send_first_confirmation_reminders
    send_second_confirmation_reminders
  end

  ##
  # Destroy old User records corresponding to users who signed up but never confirmed their email address.
  # This will trigger the destruction of associated records (opml_import_job_state, etc).
  # The interval after which an unconfirmed signup is discarded is configured with
  # the config.discard_unconfirmed_signups_after option in config/application.rb

  def self.destroy_old_signups
    signups_older_than = Time.zone.now - Feedbunch::Application.config.discard_unconfirmed_signups_after
    Rails.logger.info "Destroying unconfirmed users signed up before #{signups_older_than}"

    old_unconfirmed_signups = User.
      where 'confirmed_at is null AND confirmation_sent_at < ?',
            signups_older_than

    if old_unconfirmed_signups.empty?
      Rails.logger.info 'No old unconfirmed signups need to be destroyed'
      return
    end
    Rails.logger.info "Destroying #{old_unconfirmed_signups.count} old unconfirmed signups"

    old_unconfirmed_signups.destroy_all
  end

  ##
  # Send a reminder email to users who signed up but didn't confirm their email.
  # This method sends the first reminder email.
  # The time after signup that the first reminder is sent is configured in these config/application.rb value:
  # config.first_confirmation_reminder_after

  def self.send_first_confirmation_reminders
    signups_older_than = Time.zone.now - Feedbunch::Application.config.first_confirmation_reminder_after
    Rails.logger.info "Sending first confirmation reminder to unconfirmed users signed up before #{signups_older_than}"

    old_unconfirmed_signups = User.
        where 'confirmed_at is null AND confirmation_sent_at < ? AND first_confirmation_reminder_sent = ? AND invitation_sent_at is null',
              signups_older_than, false

    if old_unconfirmed_signups.empty?
      Rails.logger.info 'No old unconfirmed signups need to be sent a first reminder'
      return
    end
    Rails.logger.info "Sending #{old_unconfirmed_signups.count} first reminders to old unconfirmed signups"

    old_unconfirmed_signups.find_each do |user|
      Rails.logger.info "Sending first reminder to #{user.id} - #{user.email}"
      SignupConfirmationReminderMailer.reminder_email(user).deliver_now
      user.update first_confirmation_reminder_sent: true
    end
  end
  private_class_method :send_first_confirmation_reminders

  ##
  # Send a reminder email to users who signed up but didn't confirm their email.
  # This method sends the second reminder email.
  # The time after signup that the second reminder is sent is configured in these config/application.rb value:
  # config.second_confirmation_reminder_after

  def self.send_second_confirmation_reminders
    signups_older_than = Time.zone.now - Feedbunch::Application.config.second_confirmation_reminder_after
    Rails.logger.info "Sending second confirmation reminder to unconfirmed users signed up before #{signups_older_than}"

    old_unconfirmed_signups = User.
        where 'confirmed_at is null AND confirmation_sent_at < ? AND second_confirmation_reminder_sent = ? AND invitation_sent_at is null',
              signups_older_than, false

    if old_unconfirmed_signups.empty?
      Rails.logger.info 'No old unconfirmed signups need to be sent a second reminder'
      return
    end
    Rails.logger.info "Sending #{old_unconfirmed_signups.count} second reminders to old unconfirmed signups"

    old_unconfirmed_signups.find_each do |user|
      Rails.logger.info "Sending second reminder to #{user.id} - #{user.email}"
      SignupConfirmationReminderMailer.reminder_email(user).deliver_now
      user.update second_confirmation_reminder_sent: true
    end
  end
  private_class_method :send_second_confirmation_reminders
end
