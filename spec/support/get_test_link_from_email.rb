# Methods to convert absolute URLs in links into relative URLs.
# This is necessary because the URLs in emails sent during testing have host: localhost and port: 3000,
# but port 3000 in localhost is not really made available by Capybara. We need to use a relative
# URL when trying to access these URLs during testing.

##
# Given a confirmation link sent in a sign up email, returns a relative URL that can be accessed
# to confirm the new user's email address during testing.
#

def get_confirm_address_link_from_email(email_link)
  uri = URI email_link
  confirm_uri = URI confirmation_path
  confirm_uri.query = uri.query
  confirm_link = confirm_uri.to_s
  return confirm_link
end

##
# Given a password change link sent in an email, returns a relative URL that can be accessed
# to change the password.
#

def get_password_change_link_from_email(email_link)
  uri = URI email_link
  pwd_change_uri = URI edit_user_password_path
  pwd_change_uri.query = uri.query
  pwd_change_link = pwd_change_uri.to_s
  return pwd_change_link
end

##
# Given an unlock link sent in an email, returns a relative URL that can be accessed
# to change the password.
#

def get_unlock_link_from_email(email_link)
  uri = URI email_link
  unlock_uri = URI unlock_account_path
  unlock_uri.query = uri.query
  unlock_link = unlock_uri.to_s
  return unlock_link
end