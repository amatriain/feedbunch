# God configuration file for notifications.

# Rails environment defaults to development
rails_env = ENV['RAILS_ENV'] || 'development'

# Load secrets for the current Rails environment.
# The Rails.application.secrets API cannot be used because God itself does not load a full Rails environment.
secrets_file = YAML.load_file File.join(app_root, 'config', 'secrets.yml')
secrets = secrets_file[rails_env]

# A bit of monkeypatching for SMTP notifications to work with STARTTLS.
Net::SMTP.class_eval do
  def initialize_with_starttls(*args)
    initialize_without_starttls(*args)
    enable_starttls_auto
  end

  alias_method :initialize_without_starttls, :initialize
  alias_method :initialize, :initialize_with_starttls
end

# Email notifications defaults.
# In production and staging notifications are sent via SMTP.
# In other environments notifications are sent via sendmail (normally to root@localhost)
God::Contacts::Email.defaults do |d|
  d.from_email = "god.#{rails_env}@feedbunch.com"
  d.from_name = "God #{rails_env.upcase}"

  if %w{production staging}.include? rails_env
    d.delivery_method = :smtp
    d.server_host = secrets['smtp_address']
    d.server_domain = secrets['smtp_address']
    d.server_auth = :login
    d.server_user = secrets['smtp_user_name']
    d.server_password = secrets['smtp_password']
  else
    d.delivery_method = :sendmail
  end

end

God.contact(:email) do |c|
  c.name = secrets['god_contact_name']
  c.group = 'admins'
  c.to_email = secrets['god_contact_email']
end