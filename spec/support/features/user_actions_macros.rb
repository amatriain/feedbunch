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
# Open a folder in the sidebar. Receives the folder id as argument, accepts "all" to open
# the All Subscriptions folder.

def open_folder(folder_id)
  page.should have_css "#folders-list li#folder-#{folder_id}"
  # Open folder only if it is closed
  if !page.has_css? "#folders-list ul#feeds-#{folder_id}.in"
    find("a[data-target='#feeds-#{folder_id}']").click
  end
end

##
# Click on a feed to read its entries during acceptance testing. Receives as arguments:
#
# - feed_id: mandatory argument, with the id of the id of the feed to read.
# - folder_id: optional argument, with the id of the folder under which the feed will be clicked.
#
# The folder_id argument accepts the value "all"; this means the feed will be clicked under the All Subscriptions
# folder.
#
# If the folder_id argument is not present, it defaults to "all".
#
# If the feed is not under the folder passed as argument, the test will immediately fail.

def read_feed(feed_id, folder_id = 'all')
  open_folder folder_id
  within "#folders-list li#folder-#{folder_id}" do
    page.should have_css "[data-sidebar-feed][data-feed-id='#{feed_id}']"

    # Click on feed to read its entries
    find("[data-sidebar-feed][data-feed-id='#{feed_id}']").click
  end
end

##
# Click on the "read all subscriptions" link under a folder to read its entries during acceptance testing.
# Receives as argument:
#
# - folder_id: mandatory argument, with the id of the id of the feed to read. It accepts the special value "all",
# which means clicking on "read all subscriptions" under the All Subscriptions folder.
#
# If the folder does not exist, the test will immediately fail.

def read_folder(folder_id)
  open_folder folder_id
  within "#folders-list li#folder-#{folder_id}" do
    find("[data-sidebar-feed][data-feed-id='all']").click
  end
end

##
# Click on a feed to read it, and then click on the Folder dropdown to move it to a newly created folder
#
# Receives as arguments the id of the feed and the title of the new folder.

def add_feed_to_new_folder(feed_id, title)
  read_feed feed_id
  sleep 1
  find('#folder-management').click
  within '#folder-management-dropdown ul.dropdown-menu' do
    find('a[data-folder-id="new"]').click
  end
  sleep 1
  within '#new-folder-popup' do
    fill_in 'Title', with: title
    find('#new-folder-submit').click
  end
  sleep 1
end

##
# Click on a feed to read it, and then click on the Folder dropdown to move it to an already existing folder
#
# Receives as arguments the id of the feed and the id of the folder.

def add_feed_to_folder(feed_id, folder_id)
  read_feed feed_id
  sleep 1
  find('#folder-management').click
  within '#folder-management-dropdown ul.dropdown-menu' do
    find("a[data-folder-id='#{folder_id}']").click
  end
end

##
# Click on a feed to read it, and then click on the Folder dropdown to remove it from its current folder.
#
# Receives as arguments the id of the feed.

def remove_feed_from_folder(feed_id)
  read_feed feed_id
  sleep 1
  find('#folder-management').click
  within '#folder-management-dropdown ul.dropdown-menu' do
    find('a[data-folder-id="none"]').click
  end
end