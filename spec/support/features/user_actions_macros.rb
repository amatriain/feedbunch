##
# Perform the actions a user would do to login.
#
# This method is intended to be called during an acceptance (also called feature) test.

def login_user_for_feature(user)
  visit new_user_session_path
  fill_in 'Email', with: user.email
  fill_in 'Password', with: user.password
  click_on 'Sign in'
  user_should_be_logged_in
end

##
# Log out a currently logged in user

def logout_user
  user_should_be_logged_in
  open_user_menu
  find('a#sign_out').click
  expect(current_path).to eq root_path
end

##
# Open the user dropdown menu, which contains the logout etc links

def open_user_menu
  user_should_be_logged_in
  find('#user-dropdown .dropdown-toggle').click
  expect(page).to have_css 'a#sign_out', visible: true
end

##
# Open the feeds dropdown menu, which contains the refresh etc links

def open_feeds_menu
  user_should_be_logged_in
  find('#feed-dropdown .dropdown-toggle').click
  expect(page).to have_css 'a#add-subscription', visible: true
end

##
# Perform the actions a user would do to try and fail to login, be it
# because of a wrong username, wrong password, locked user or any other reason.
#
# Receives as arguments the username and password to enter into the login form.
#
# This method is intended to be called during an acceptance test.

def failed_login_user_for_feature(username, password)
  visit new_user_session_path
  fill_in 'Email', with: username
  fill_in 'Password', with: password
  click_on 'Sign in'
  user_should_not_be_logged_in
end

##
# Open a folder in the sidebar. Receives the folder as argument.

def open_folder(folder)
  expect(page).to have_css "#folders-list #folder-#{folder.id}"
  # Open folder only if it is closed
  if !page.has_css? "#folders-list #feeds-#{folder.id}.in"
    find("a#open-folder-#{folder.id}").click
    expect(page).to have_css "#folders-list #feeds-#{folder.id}.in"
  end
end

##
# Click on a feed to read its entries during acceptance testing. Receives as arguments:
#
# - feed: mandatory argument, with the feed to read.
# - user: mandatory argument, with the user performing the action.

def read_feed(feed, user)
  folder = feed.user_folder user
  open_folder folder if folder.present?
  folder_id = folder.try(:id) || 'none'
  within "#folders-list #folder-#{folder_id}" do
    expect(page).to have_css "[data-sidebar-feed][data-feed-id='#{feed.id}']", visible: true

    # Click on feed to read its entries
    find("[data-sidebar-feed][data-feed-id='#{feed.id}']", visible: true).click
  end

  # Ensure entries have finished loading
  expect(page).not_to have_css 'div#loading'
end

##
# Click on the "all subscriptions" link under a folder to read its entries during acceptance testing.
# Receives as argument:
#
# - folder: mandatory argument, with the id of the id of the feed to read. It accepts the special value "all",
# which means clicking on "all subscriptions" link above the folders list, which loads all entries for
# all subscribed feeds.
#
# If the folder does not exist, the test will immediately fail.

def read_folder(folder)
  # The spinners in the sidebar should be hidden, to indicate that feeds and folders have finished loading
  expect(page).not_to have_css '#sidebar i.fa-spinner.fa-spin', visible: true

  open_folder folder if folder != 'all'
  folder_id = (folder == 'all')? 'none' : folder.id
  within "#folders-list #folder-#{folder_id}" do
    find("[data-sidebar-feed][data-feed-id='all']").click
  end

  # Ensure entries have finished loading
  expect(page).not_to have_css 'div#loading'
end

##
# Click on an entry to open and read it. Receives as argument the entry to be read.
#
# If the entry is not in the entries list, the test will immediately fail.
# If the entry is not unread, the test will immediately fail.

def read_entry(entry)
  expect(page).to have_css "#feed-entries #entry-#{entry.id}"
  entry_should_be_marked_unread entry
  open_entry entry
  entry_should_be_marked_read entry
end

##
# Mark an entry as unread. Receives as argument the entry to be read.
#
# If the entry is not in the entries list, the test will immediately fail.
# If the entry is not read, the test will immediately fail
# If the entry is not open, it is opened before marking it as unread.

def unread_entry(entry)
  expect(page).to have_css "#feed-entries #entry-#{entry.id}"
  entry_should_be_marked_read entry
  open_entry entry
  find("div[id='entry-#{entry.id}'] a[ng-click='unread_entry(entry)']").click
  entry_should_be_marked_unread entry
end

##
# Open a single entry, if it is not already open.
#
# If the entry is not in the entries list, the test will immediately fail.

def open_entry(entry)
  expect(page).to have_css "#feed-entries #entry-#{entry.id}"

  # Open entry only if it is closed
  if !page.has_css? "#feed-entries #entry-#{entry.id}-summary", visible: true
    find("#feed-entries [data-entry-id='#{entry.id}']").click
    expect(page).to have_css "#feed-entries #entry-#{entry.id}-summary", visible: true
  end
end

##
# Click on an entry to close it. Receives as argument the entry to be closed.
#
# If the entry is not currently in the entries list, the test will immediately fail.

def close_entry(entry)
  expect(page).to have_css "#feed-entries #entry-#{entry.id}"

  # Close entry only if it is open
  if page.has_css? "#feed-entries #entry-#{entry.id}-summary.in"
    find("#feed-entries [data-entry-id='#{entry.id}']").click
    expect(page).not_to have_css "#feed-entries #entry-#{entry.id}-summary.in"
  end
end

##
# Click on the "share" button in an entry's toolbar, to open the dropdown menu.

def open_entry_share_dropdown(entry)
  # Open entry if not already open
  open_entry entry

  # Ensure button is visible
  expect(page).to have_css "#entry-#{entry.id}-summary .entry-toolbar a[data-share-entry-dropdown]", visible: true

  #Only open dropdown if it's closed
  expect(page).not_to have_css "#entry-#{entry.id}-summary .entry-toolbar div.open > a[data-share-entry-dropdown]"

  find("#entry-#{entry.id}-summary .entry-toolbar a[data-share-entry-dropdown]").click
  expect(page).to have_css "#entry-#{entry.id}-summary .entry-toolbar div.open > a[data-share-entry-dropdown]"
end

##
# Click on the "refresh feed" button to fetch new entries for the feed

def refresh_feed
  open_feeds_menu
  expect(page).to have_css '#refresh-feed'
  find('#refresh-feed').click
  # Ensure entries have finished loading
  expect(page).not_to have_css 'div#loading'
end

##
# Click on the "mark all as read" button to mark all currently visible entries as read.
#
# If the button is not currently visible the test immediately fails.

def mark_all_as_read
  find('#read-all-button').click
  expect(page).not_to have_css 'feed-entries a[data-entry-id].entry-unread'
  expect(page).not_to have_css 'feed-entries a[data-entry-id].entry-becoming-read'
end

##
# Click on the "Show read" button so that all feeds and entries are displayed, including read ones.

def show_read
  find('#show-read').click

  # Ensure entries have finished loading
  expect(page).not_to have_css 'div#loading'
end

##
# Click on the "Hide read" button so that only unread feeds and entries are displayed.

def hide_read
  find('#hide-read').click

  # Ensure entries have finished loading
  expect(page).not_to have_css 'div#loading'
end

##
# Click on the "folders" button to open the folders dropdown for the currently selected feed.

def open_folder_dropdown
  # Only click on button if it's enabled
  expect(page).to have_css '#folder-management-dropdown #folder-management'
  expect(page).not_to have_css '#folder-management-dropdown #folder-management.disabled'

  #Only open dropdown if it's closed
  expect(page).not_to have_css '#folder-management-dropdown.open'

  find('#folder-management').click
  expect(page).to have_css '#folder-management-dropdown.open'
end

##
# Click on a feed to read it, and then click on the Folder dropdown to move it to a newly created folder
#
# Receives as arguments:
# - the feed to be moved
# - the title of the new folder
# - the user performing the action

def move_feed_to_new_folder(feed, title, user)
  read_feed feed, user
  open_folder_dropdown
  within '#folder-management-dropdown ul.dropdown-menu' do
    find('a[data-folder-id="new"]').click
  end
  expect(page).to have_css '#new-folder-popup'
  within '#new-folder-popup' do
    fill_in 'Title', with: title
    find('#new-folder-submit').click
  end
  # Ensure new feed appears in the sidebar
  within '#folders-list' do
    expect(page).to have_text title
  end
end

##
# Click on a feed to read it, and then click on the Folder dropdown to move it to an already existing folder
#
# Receives as arguments:
# - the feed to be moved
# - the folder to which it will be moved
# - the user performing the action

def move_feed_to_folder(feed, folder, user)
  read_feed feed, user
  open_folder_dropdown
  within '#folder-management-dropdown ul.dropdown-menu' do
    find("a[data-folder-id='#{folder.id}']").click
  end

  # Ensure feed has been moved to folder
  open_folder folder
  expect(page).to have_css "#folders-list #folder-#{folder.id} [data-sidebar-feed][data-feed-id='#{feed.id}']"
  within "#folder-management-dropdown ul.dropdown-menu a[data-folder-id='#{folder.id}']", visible: false do
    expect(page).to have_css 'i.fa.fa-check', visible: false
    expect(page).not_to have_css 'i.fa.fa-check.hidden', visible: false
  end
end

##
# Click on a feed to read it, and then click on the Folder dropdown to remove it from its current folder.
#
# Receives as arguments:
# - the feed to be removed from its folder
# - the user performing the action

def remove_feed_from_folder(feed, user)
  folder = feed.user_folder user
  folder_id = folder.try(:id) || 'none'
  read_feed feed, user
  open_folder_dropdown
  within '#folder-management-dropdown ul.dropdown-menu' do
    find('a[data-folder-id="none"]').click
  end

  # Ensure feed has been removed from folder
  expect(page).not_to have_css "#folders-list li#folder-#{folder_id} [data-sidebar-feed][data-feed-id='#{feed.id}']"
end

##
# Click on the Subscribe button, enters the URL passed as argument in the popup form, and submit the form.
# Receives as argument the URL to enter in the Add Subscription popup form.

def subscribe_feed(url)
  open_feeds_menu
  find('#add-subscription').click
  expect(page).to have_css '#subscribe-feed-popup'
  within '#subscribe-feed-popup' do
    fill_in 'Feed', with: url
    find('#subscribe-submit').click
  end

  # Ensure entries have finished loading
  expect(page).not_to have_css 'div#loading'
end

##
# Click on the Unsubscribe button and then click on Accept in the confirmation popup.
# Receives as arguments:
# - the feed to unsubscribe
# - the user performing the action

def unsubscribe_feed(feed, user)
  read_feed feed, user
  open_feeds_menu
  find('#unsubscribe-feed').click
  find('#unsubscribe-submit').click

  # Ensure popup has closed
  expect(page).not_to have_css '#unsubscribe-feed-popup'

  # Ensure user is shown the start page
  expect(page).to have_css '#sidebar li.active a#start-page'
end

##
# Enter the edit registration page, check the "enable quick reading" checkbox if it isn't already,
# enter the current password and save the changes.
# Receives as argument the user performing the action.

def enable_quick_reading(user)
  visit edit_user_registration_path

  # capybara check method currently not working because of a capybara-webkit bug: see https://github.com/thoughtbot/capybara-webkit/issues/494
  #check 'user_quick_reading'

  # instead we click the checkbox with javascript (dirty hack suggested in the above bug comments):
  page.execute_script('$("#user_quick_reading").click()')

  fill_in 'user_current_password', with: user.password
  click_on 'Update account'
  expect(current_path).to eq read_path
end

##
# Enter the edit registration page, check the "open all entries" checkbox if it isn't already,
# enter the current password and save the changes.
# Receives as argument the user performing the action.

def enable_open_all_entries(user)
  visit edit_user_registration_path

  # capybara check method currently not working because of a capybara-webkit bug: see https://github.com/thoughtbot/capybara-webkit/issues/494
  #check 'user_open_all_entries'

  # instead we click the checkbox with javascript (dirty hack suggested in the above bug comments):
  page.execute_script('$("#user_open_all_entries").click()')

  fill_in 'user_current_password', with: user.password
  click_on 'Update account'
  expect(current_path).to eq read_path
end

##
# Click on the "Start" link in the sidebar to go to the start page

def go_to_start_page
  find('#sidebar #start-page').click
end

##
# Click on the "close" button of the currently displayed opml-import alert

def close_import_alert
  find('#start-info #import-process-state button.close', visible: true).click
end

##
# Click on the "close" button of the currently displayed opml-export alert

def close_export_alert
  find('#start-info #export-process-state button.close', visible: true).click
end

##
# Click on the "close" button of a currently visible refresh feed job state alert.
#
# Receives the id of the job as argument.

def close_refresh_feed_job_alert(job_id)
  find("#start-info #job-states #refresh-state-#{job_id} button.close", visible: true).click
end

##
# Click on the "close" button of a currently visible subscribe job state alert.
#
# Receives the id of the job as argument.

def close_subscribe_job_alert(job_id)
  find("#start-info #job-states #subscribe-state-#{job_id} button.close", visible: true).click
end

##
# Go to the edit account page and click on the "export subscriptions" button.

def export_subscriptions
  visit edit_user_registration_path
  find("a[href*='#{api_opml_exports_path}']").click
end

##
# Send an invitation to a friend.
#
# Receives as argument the friend's email address

def send_invitation(invited_email)
  visit edit_user_registration_path
  find('#send-invitation-button').click
  expect(page).to have_css '#invite-friend-popup', visible: true
  fill_in 'user_invitation_email', with: invited_email
  click_on 'Send invitation'
  expect(page).not_to have_css '#invite-friend-popup', visible: true
end

##
# Accept an invitation to join Feedbunch.
# Optional arguments:
# - the password to set for the user. If not passed, the default string "some_password" will be used.
# - the accept link present in the sent email. If the accept link is not passed, the invitation email
# is popped from the ActionMailer deliveries queue.
# - email address to which the invitation is sent. This argument is only used if the accept_link argument
# is not passed; in this case, if the invited_email argument is passed, the method validates that the
# invitation email is sent to this email address. If neither accept_invitation nor invited_email are passed,
# the email address to which the invitation is sent will not be validated.
#
# Important: an email can be popped from the deliveries queue only once. This means that if the test that
# invokes this function needs to do some validation on the invitation email, the email must be popped
# and parsed in the test, and the accept link must be passed as argument to this function, because the
# function has no way to retrieve the accept link otherwise.

def accept_invitation(password: nil, accept_link: nil, invited_email: nil)
  password ||= 'some_password'
  if accept_link.nil?
    email_params = {path: '/invitation', text: 'Someone has invited you'}
    email_params.merge!({to: invited_email}) if invited_email.present?
    accept_link = mail_should_be_sent email_params
  end
  accept_url = get_accept_invitation_link_from_email accept_link
  visit accept_url
  fill_in 'Password', with: password
  fill_in 'Confirm password', with: password
  click_on 'Activate account'
  expect(current_path).to eq read_path
  user_should_be_logged_in
end

##
# Sign up a new user account.
# Receives as arguments the email address and password for the new account.

def sign_up(email, password)
  visit new_user_registration_path
  fill_in 'Email', with: email
  fill_in 'Password', with: password
  fill_in 'Confirm password', with: password
  click_on 'Sign up'
  expect(current_path).to eq root_path

  # test that a confirmation email is sent
  confirmation_link = mail_should_be_sent path: confirmation_path, to: email

  # Test that user cannot login before confirming the email address
  failed_login_user_for_feature email, password

  # Convert the link sent by email into a relative URL that can be accessed during testing
  confirmation_url = get_confirm_address_link_from_email confirmation_link
  # Follow confirmation link received by email, user should be able to log in afterwards
  visit confirmation_url
end