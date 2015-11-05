# Declare sidekiq-cron jobs (sidekiq workers that must be run periodically)
#
# cron format: (minute hour day-of-month month day-of-week)

Sidekiq.configure_server do |config|
  Sidekiq::Cron::Job.create name: 'Cleanup old invitations - daily at 2AM',
                            cron: '0 2 * * *',
                            klass: 'CleanupInvitationsWorker',
                            queue: :maintenance

  Sidekiq::Cron::Job.create name: 'Cleanup old signups - daily at 3AM',
                            cron: '0 3 * * *',
                            klass: 'CleanupSignupsWorker',
                            queue: :maintenance

  Sidekiq::Cron::Job.create name: 'Cleanup old signups - daily at 4AM',
                            cron: '0 4 * * *',
                            klass: 'DestroyOldJobStatesWorker',
                            queue: :maintenance

  Sidekiq::Cron::Job.create name: 'Restore missing scheduled feed updates - daily at 5AM',
                            cron: '0 5 * * *',
                            klass: 'FixSchedulesWorker',
                            queue: :maintenance

  Sidekiq::Cron::Job.create name: 'Reset the demo user - hourly',
                            cron: '0 * * * *',
                            klass: 'ResetDemoUserWorker',
                            queue: :maintenance

  Sidekiq::Cron::Job.create name: 'Update the statistics of the Rails cache - every 10 minutes',
                            cron: '*/10 * * * *',
                            klass: 'UpdateRedisCacheStatsWorker',
                            queue: :maintenance
end
