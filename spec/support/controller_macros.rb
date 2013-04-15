##
# Login a user using Devise helpers
#
# This method is intended to be called during a unit test, normally for a controller (but not necessarily).

def login_user_for_unit(user)
  @request.env['devise.mapping'] = Devise.mappings[:user]
  sign_in user
end