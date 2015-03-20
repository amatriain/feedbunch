# Configuration for the demo user. It is reset every hour by the ResetDemoUserWorker sidekiq worker.

# If this config is not set to true, the demo user will be disabled. In fact each run of ResetDemoUserWorker will
# delete it if it exists.
# If this config is not set to true the rest of options in this file will be ignored.
Feedbunch::Application.config.demo_enabled = true

# Demo user authentication
Feedbunch::Application.config.demo_email = 'demo@feedbunch.com'
Feedbunch::Application.config.demo_password = 'feedbunch-demo'
