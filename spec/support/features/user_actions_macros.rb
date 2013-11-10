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
  current_path.should eq root_path
end

##
# Open the user dropdown menu, which contains the logout etc links

def open_user_menu
  user_should_be_logged_in
  find('#user-dropdown .dropdown-toggle').click
  page.should have_css 'a#sign_out', visible: true
end

##
# Open the feeds dropdown menu, which contains the refresh etc links

def open_feeds_menu
  user_should_be_logged_in
  find('#feed-dropdown .dropdown-toggle').click
  page.should have_css 'a#add-subscription', visible: true
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
  page.should have_css "#folders-list #folder-#{folder.id}"
  # Open folder only if it is closed
  if !page.has_css? "#folders-list #feeds-#{folder.id}.in"
    find("a#open-folder-#{folder.id}").click
    page.should have_css "#folders-list #feeds-#{folder.id}.in"
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
    page.should have_css "[data-sidebar-feed][data-feed-id='#{feed.id}']", visible: true

    # Click on feed to read its entries
    find("[data-sidebar-feed][data-feed-id='#{feed.id}']", visible: true).click
  end

  # Ensure entries have finished loading
  page.should_not have_css 'div#loading'
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
  open_folder folder if folder != 'all'
  folder_id = (folder == 'all')? 'none' : folder.id
  within "#folders-list #folder-#{folder_id}" do
    find("[data-sidebar-feed][data-feed-id='all']").click
  end

  # Ensure entries have finished loading
  page.should_not have_css 'div#loading'
end

##
# Click on an entry to open and read it. Receives as argument the entry to be read.
#
# If the entry is not currently in the entries list, the test will immediately fail.

def read_entry(entry)
  page.should have_css "#feed-entries #entry-#{entry.id}"

  # Open entry only if it is closed
  if !page.has_css? "#feed-entries #entry-#{entry.id}-summary.in"
    find("#feed-entries [data-entry-id='#{entry.id}']").click
    page.should have_css "#feed-entries #entry-#{entry.id}-summary.in"
  end
end

##
# Click on the "refresh feed" button to fetch new entries for the feed

def refresh_feed
  open_feeds_menu
  page.should have_css '#refresh-feed'
  find('#refresh-feed').click
  # Ensure entries have finished loading
  page.should_not have_css 'div#loading'
end

##
# Click on the "mark all as read" button to mark all currently visible entries as read.
#
# If the button is not currently visible the test immediately fails.

def mark_all_as_read
  find('#read-all-button').click
  page.should_not have_css 'feed-entries a[data-entry-id].entry-unread'
end

##
# Click on the "Show read" button so that all feeds and entries are displayed, including read ones.

def show_read
  find('#show-read').click

  # Ensure entries have finished loading
  page.should_not have_css 'div#loading'
end

##
# Click on the "Hide read" button so that only unread feeds and entries are displayed.

def hide_read
  find('#hide-read').click

  # Ensure entries have finished loading
  page.should_not have_css 'div#loading'
end

##
# Click on the "folders" button to open the folders dropdown for the currently selected feed.

def open_folder_dropdown
  # Only click on button if it's enabled
  page.should have_css '#folder-management-dropdown #folder-management'
  page.should_not have_css '#folder-management-dropdown #folder-management.disabled'

  #Only open dropdown if it's closed
  page.should_not have_css '#folder-management-dropdown.open'

  find('#folder-management').click
  page.should have_css '#folder-management-dropdown.open'
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
  page.should have_css '#new-folder-popup'
  within '#new-folder-popup' do
    fill_in 'Title', with: title
    find('#new-folder-submit').click
  end
  # Ensure new feed appears in the sidebar
  within '#folders-list' do
    page.should have_text title
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
  page.should have_css "#folders-list #folder-#{folder.id} [data-sidebar-feed][data-feed-id='#{feed.id}']"
  within "#folder-management-dropdown ul.dropdown-menu a[data-folder-id='#{folder.id}']", visible: false do
    page.should have_css 'i.fa.fa-check', visible: false
    page.should_not have_css 'i.fa.fa-check.hidden', visible: false
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
  page.should_not have_css "#folders-list li#folder-#{folder_id} [data-sidebar-feed][data-feed-id='#{feed.id}']"
end

##
# Click on the Subscribe button, enters the URL passed as argument in the popup form, and submit the form.
# Receives as argument the URL to enter in the Add Subscription popup form.

def subscribe_feed(url)
  open_feeds_menu
  find('#add-subscription').click
  page.should have_css '#subscribe-feed-popup'
  within '#subscribe-feed-popup' do
    fill_in 'Feed', with: url
    find('#subscribe-submit').click
  end

  # Ensure entries have finished loading
  page.should_not have_css 'div#loading'
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

  # Ensure user is shown the start page
  page.should have_css '#sidebar li.active a#start-page'
end