# Redis server location
Sidekiq.configure_server do |config|
  config.redis = { url: Rails.application.secrets.redis_background }
end

Sidekiq.configure_client do |config|
  config.redis = { url: Rails.application.secrets.redis_web }
end