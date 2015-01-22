# Define superworkers for the sidekiq-superworker gem.

Superworker.define :ImportSubscriptionsWorker, :opml_import_job_state_id, :urls, :folders do
  batch urls: :url, folders: :folder do
    ImportSubscriptionWorker :opml_import_job_state_id, :url, :folder
  end
end