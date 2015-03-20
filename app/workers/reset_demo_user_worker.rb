##
# Background worker to create the demo user (if it doesn't exist yet) and reset its configuration, folders and
# subscribed feeds.
#
# The credentials for the demo user are:
# - email: demo@feedbunch.com
# - password: feedbunch-demo
#
# This is a Sidekiq worker

class ResetDemoUserWorker
  include Sidekiq::Worker
  include Sidetiq::Schedulable

  # This worker runs periodically. Do not retry.
  sidekiq_options retry: false, queue: :maintenance
  # Run every hour.
  recurrence do
    hourly
  end

  ##
  # Create the demo user if it still doesn't exist. Reset its configuration, folders and subscribed feeds.

  def perform
    Rails.logger.debug 'Resetting demo user'

    unless Feedbunch::Application.config.demo_enabled
      Rails.logger.info 'Demo user is disabled'
      # If the demo user is disabled in the configuration, just destroy it if it exists and do nothing else.
      destroy_demo_user
      return
    end

    unless User.exists? email: Feedbunch::Application.config.demo_email
      demo_user = User.new email: Feedbunch::Application.config.demo_email,
                           password: Feedbunch::Application.config.demo_password,
                           confirmed_at: Time.zone.now
      Rails.logger.debug 'Demo user does not exist, creating it'
      demo_user.save!
    end
  end

  private

  ##
  # Destroy the demo user, if it exists.

  def destroy_demo_user
    if User.exists? email: Feedbunch::Application.config.demo_email
      Rails.logger.warn 'Demo user disabled but exists in the database. Destroying it.'
      demo_user = User.find_by_email Feedbunch::Application.config.demo_email
      demo_user.destroy
    end
  end
end