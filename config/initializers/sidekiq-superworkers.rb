# Define superworkers for the sidekiq-superworker gem.

Superworker.define :ImportSubscriptionsWorker, :urls, :user, :folders do
  batch urls: :url, folders: :folder do
    ImportSubscriptionWorker :url, :user, :folder
  end
end