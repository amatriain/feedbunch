# God configuration file for notifications.

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
  d.from_email = "god.#{Rails.env}@feedbunch.com"
  d.from_name = "God #{Rails.env.upcase}"

  if %w{production staging}.include? Rails.env
    d.delivery_method = :smtp
    d.server_host = Rails.application.secrets.smtp_address
    d.server_domain = Rails.application.secrets.smtp_address
    d.server_auth = :login
    d.server_user = Rails.application.secrets.smtp_user_name
    d.server_password = Rails.application.secrets.smtp_password
  else
    d.delivery_method = :sendmail
  end

end

God.contact(:email) do |c|
  c.name = Rails.application.secrets.god_contact_name
  c.group = 'admins'
  c.to_email = Rails.application.secrets.god_contact_email
end