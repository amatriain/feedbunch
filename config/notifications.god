# God configuration file for notifications.

# Send email notifications to root@localhost. There can be
# a forward rule in the OS to send these emails to the admin
God::Contacts::Email.defaults do |d|
  d.from_email = 'god@feedbunch.com'
  d.from_name = 'God DEVELOPMENT'
  d.delivery_method = :sendmail
end

God.contact(:email) do |c|
  c.name = 'admin'
  c.group = 'admins'
  c.to_email = 'root@localhost'
end