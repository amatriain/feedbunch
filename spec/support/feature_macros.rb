##
# Perform the actions a user would do to login.
#
# This method is intended to be called during an acceptance (also called feature) test.

def login_user_for_feature(user)
  visit new_user_session_path
  fill_in 'Email', with: user.email
  fill_in 'Password', with: user.password
  click_on 'Sign in'
end

##
# Test that a user is logged in, during an acceptance test.
#
# To see if the user is logged in, we check the presence of a "Logout" link in the navbar.

def user_should_be_logged
  page.should have_css 'div.navbar div.navbar-inner ul li a#sign_out'
end

##
# Test that a user is not logged in, during an acceptance test.
#
# To see if the user is not logged in, we check the absence of a "Logout" link in the navbar.

def user_should_not_be_logged
  page.should_not have_css 'div.navbar div.navbar-inner ul li a#sign_out'
end