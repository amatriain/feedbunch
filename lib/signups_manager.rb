##
# Class with methods related to managing data created when a user signs up.

class SignupsManager

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
end