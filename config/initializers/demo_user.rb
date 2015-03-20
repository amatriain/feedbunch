# Configuration for the demo user. It is reset every hour by the ResetDemoUserWorker sidekiq worker.

Feedbunch::Application.config.demo_email = 'demo@feedbunch.com'
Feedbunch::Application.config.demo_password = 'feedbunch-demo'
