##
# Class with methods related to managing invitations sent to potential users.

class InvitationsManager

  ##
  # Destroy old User records corresponding to invitations sent but never accepted.
  # This will trigger the destruction of associated records (opml_import_job_state, etc).
  # The interval after which an unaccepted invitation is discarded is configured with
  # the config.discard_unaccepted_invitations_after option in config/application.rb

  def self.destroy_old_invitations
    invitations_older_than = Time.zone.now - Feedbunch::Application.config.discard_unaccepted_invitations_after
    Rails.logger.info "Destroying unaccepted invitations sent before #{invitations_older_than}"

    old_unaccepted_invitations = User.
      where 'invitation_token is not null AND invitation_accepted_at is null AND invitation_sent_at < ?',
            invitations_older_than

    if old_unaccepted_invitations.empty?
      Rails.logger.info 'No old unaccepted invitations need to be destroyed'
      return
    end
    Rails.logger.info "Destroying #{old_unaccepted_invitations.count} old unaccepted invitations"

    old_unaccepted_invitations.destroy_all
  end

  ##
  # Set the daily invitations limit for all users to the value configured in application.rb, in the
  # daily_invitations_limit config option.

  def self.update_daily_limit
    limit = Feedbunch::Application.config.daily_invitations_limit
    Rails.logger.info "Setting the daily invitations limit for all users to #{limit}"
    users = User.where 'invitation_limit != ? or invitation_limit is null', limit
    Rails.logger.debug "A total of #{users.length} users have an invitation limit that needs updating"
    users.each {|u| u.update invitation_limit: limit}
  end
end