# Admin email can be set with the "ADMIN_EMAIL" environment variable.
# It takes the value admin@feedbunch.com by default.
admin_email = ENV.fetch("ADMIN_EMAIL") { 'admin@feedbunch.com' }
Rails.application.config.admin_email = admin_email