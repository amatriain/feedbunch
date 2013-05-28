##
# Test that a user is logged in, during an acceptance test.
#
# To see if the user is logged in, we check the presence of a "Logout" link in the navbar.

def user_should_be_logged_in
  page.should have_css 'div.navbar div.navbar-inner ul li a#sign_out'
end

##
# Test that a user is not logged in, during an acceptance test.
#
# To see if the user is not logged in, we check the absence of a "Logout" link in the navbar.

def user_should_not_be_logged_in
  page.should_not have_css 'div.navbar div.navbar-inner ul li a#sign_out'
end

##
# Test that an email has been sent during acceptance testing. Accepts an options hash supporting the following options:
#
# - :path - if passed, tests that the mail contains a link to this path. Ideally we'd like to test using full URLs
# but this not possible because during testing links inside emails generated by ActionMailer use the hostname
# "www.example.com" instead of the actual "localhost:3000" returned by Rails URL helpers.
# - :to - if passed, tests that this is the value of the email's "to" header.
#
# Return value is the href of the link if "path" option is passed, nil otherwise.

def mail_should_be_sent(options={})
  default_options = {path: nil, to: nil}
  options = default_options.merge options

  email = ActionMailer::Base.deliveries.pop
  email.present?.should be_true

  if options[:path].present?
    emailBody = Nokogiri::HTML email.body.to_s
    link = emailBody.at_css "a[href*=\"#{options[:path]}\"]"
    link.present?.should be_true
    href = link[:href]
  end

  if options[:to].present?
    email.to.first.should eq options[:to]
  end

  return href
end

##
# Test that no email has been sent during acceptance testing

def mail_should_not_be_sent
  email = ActionMailer::Base.deliveries.pop
  email.present?.should be_false
end

##
# Test that the count of unread entries in a folder equals the passed argument.
# Receives as argument the folder id and the expected entry count.

def unread_folder_entries_should_eq(folder_id, count)
  within "#sidebar #folders-list #folder-#{folder_id} #feeds-#{folder_id} #folder-#{folder_id}-all-feeds" do
    page.should have_content "Read all subscriptions (#{count})"
  end
end

##
# Test that the count of unread entries in a feed equals the passed argument.
# Receives as argument the feed title, the expected entry count and optionally what folder to look at (defaults to "all")

def unread_feed_entries_should_eq(feed_title, count, folder_id='all')
  within "#sidebar #folders-list #folder-#{folder_id} #feeds-#{folder_id}" do
    page.should have_content "#{feed_title} (#{count})"
  end
end

##
# Test that an alert with the passed id is shown on the page, and that it disappears automatically
# after 5 seconds.

def should_show_alert(alert_id)
  page.should have_css "div##{alert_id}", visible: true
  page.should_not have_css "div##{alert_id}.hidden", visible: false

  # It should close automatically after 5 seconds
  sleep 5
  page.should_not have_css "div##{alert_id}", visible: true
end

##
# Test that an alert with the passed id is hidden-

def should_hide_alert(alert_id)
  page.should_not have_css "div##{alert_id}", visible: true
  page.should have_css "div##{alert_id}.hidden", visible: false
end