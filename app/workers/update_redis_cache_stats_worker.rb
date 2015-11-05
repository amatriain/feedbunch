require 'redmon'

##
# Background worker to update stats for the Redis instance serving as Rails cache backend.
# Stats are then visualized with Redmon, accessible at the /redmon path.
#
# This is a Sidekiq worker

class UpdateRedisCacheStatsWorker
  include Sidekiq::Worker

  # This worker runs periodically. Do not retry.
  sidekiq_options retry: false, queue: :maintenance

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