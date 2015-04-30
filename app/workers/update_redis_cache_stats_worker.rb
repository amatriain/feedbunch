require 'redmon'

##
# Background worker to update stats for the Redis instance serving as Rails cache backend.
# Stats are then visualized with Redmon, accessible at the /redmon path.
#
# This is a Sidekiq worker

class UpdateRedisCacheStatsWorker
  include Sidekiq::Worker
  include Sidetiq::Schedulable

  # This worker runs periodically. Do not retry.
  sidekiq_options retry: false, queue: :maintenance
  # Run every minute.
  recurrence do
    hourly.minute_of_hour 0, 10, 20, 30, 40, 50
  end

  ##
  # Update stats (memory use, configuration, last time saved etc) from the Redis instance serving as Rails cache backend.
  # Stats can be visualized with Redmon, accessible at the /redmon path.

  def perform
    Rails.logger.debug 'Updating Redmon stats for the Redis rails cache instance'
    worker = Redmon::Worker.new
    worker.record_stats
    worker.cleanup_old_stats
  end
end