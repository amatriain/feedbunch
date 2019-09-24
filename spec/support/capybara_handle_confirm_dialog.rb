# frozen_string_literal: true

##
# Automatically click accept on browser dialogs during acceptance testing.
#
# Unfortunately the Selenium driver for Capybara does not handle javascript dialogs very well.
# Some acceptance tests need to do some action on the page and click "accept" on the dialog
# that pops up.
#
# If such actions are passed as a block to this method, any accept dialogs that appear
# as a result of the action will be automatically accepted, like this:
#
#   handle_js_confirm do
#     click_on 'Cancel account'
#   end
#
# Note.- This only works in acceptance tests that have been marked to use the Selenium driver
# like this:
#
#   it 'deletes account', js: true do
#     ... whatever...
#   end
#
# This method is inspired on a {Stack Overflow post}[http://stackoverflow.com/a/2609244/1047560].

def handle_js_confirm(accept=true)
  page.evaluate_script 'window.original_confirm_function = window.confirm'
  page.evaluate_script "window.confirm = function(msg){return #{!!accept};}"
  yield
ensure
  page.evaluate_script 'window.confirm = window.original_confirm_function'
end