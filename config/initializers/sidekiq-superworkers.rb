# Define superworkers for the sidekiq-superworker gem.

Superworker.define :ImportSubscriptionsWorker, :opml_import_job_state_id, :urls, :folder_ids do
  batch urls: :url, folder_ids: :folder_id do
    ImportSubscriptionWorker :opml_import_job_state_id, :url, :folder_id
  end
end