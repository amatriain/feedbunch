# Define superworkers for the sidekiq-superworker gem.

# If subworkers die, superworker is never notified. Setting this option makes the superworker expire
# after N seconds.
Sidekiq::Superworker.options[:superjob_expiration] = 2592000 # 1 Month

Superworker.define :ImportSubscriptionsWorker, :opml_import_job_state_id, :urls, :folder_ids do
  batch urls: :url, folder_ids: :folder_id do
    ImportSubscriptionWorker :opml_import_job_state_id, :url, :folder_id
  end
  NotifyImportFinishedWorker :opml_import_job_state_id
end