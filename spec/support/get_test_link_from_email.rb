# Methods to convert absolute URLs in links into relative URLs.
# This is necessary because the URLs in emails sent during testing have host: localhost and port: 3000,
# but port 3000 in localhost is not really made available by Capybara. We need to use a relative
# URL when trying to access these URLs during testing.

##
# Given an accept link sent in an invitation email, returns a relative URL that can be accessed
# to accept an invitation during testing.
#

def get_accept_invitation_link_from_email(email_link)
  uri = URI email_link
  accept_uri = URI accept_user_invitation_path
  accept_uri.query = uri.query
  accept_invitation_link = accept_uri.to_s
  return accept_invitation_link
end

##
# Given a confirmation link sent in a sign up email, returns a relative URL that can be accessed
# to confirm the new user's email address during testing.
#

def get_confirm_address_link_from_email(email_link)
  uri = URI email_link
  confirm_uri = URI confirmation_path
  confirm_uri.query = uri.query
  confirm_invitation_link = confirm_uri.to_s
  return confirm_invitation_link
end