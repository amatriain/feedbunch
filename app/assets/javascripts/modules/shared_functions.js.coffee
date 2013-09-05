window.Feedbunch ||= {}

########################################################
# GLOBAL FUNCTIONS
########################################################

#-------------------------------------------------------
# Totally remove a folder from the sidebar and the dropdown
#-------------------------------------------------------
Feedbunch.remove_folder = (folder_id) ->
  $("#sidebar #folder-#{folder_id}").remove()
  $("#folder-management-dropdown a[data-folder-id='#{folder_id}']").parent().remove()

#-------------------------------------------------------
# Remove feed from all folders, except the All Subscriptions folder
#-------------------------------------------------------
Feedbunch.remove_feed_from_folders = (feed_id) ->
  $("[data-sidebar-feed][data-feed-id='#{feed_id}']").parent().each ->
    # Do not remove it from the "All Subscriptions" folder
    $(this).remove() if $(this).closest(".panel-collapse").attr("id") != "feeds-all"

#-------------------------------------------------------
# Insert feed in a folder in the sidebar
#-------------------------------------------------------
Feedbunch.insert_feed_in_folder = (feed_id, folder_id, feed_data) ->
  $("#folder-#{folder_id}-all-feeds").after feed_data
  if folder_id=="all"
    Feedbunch.update_folder_id feed_id, "none"
  else
    Feedbunch.update_folder_id feed_id, folder_id

#-------------------------------------------------------
# Update the data-folder-id attribute for all links to a feed in the sidebar
#-------------------------------------------------------
Feedbunch.update_folder_id = (feed_id, folder_id) ->
  $("[data-sidebar-feed][data-feed-id='#{feed_id}']").attr "data-folder-id", folder_id

#-------------------------------------------------------
# Update the count of unread entries in a folder by rewriting the "read all" link
#-------------------------------------------------------
Feedbunch.update_folder_entry_count = (folder_id, data) ->
  $("li#folder-#{folder_id}-all-feeds").replaceWith data

#-------------------------------------------------------
# Update the count of unread entries in a feed by rewriting its link in the sidebar.
#-------------------------------------------------------
Feedbunch.update_feed_entry_count = (feed_id, data) ->
  sidebar_feed = $("[data-sidebar-feed][data-feed-id='#{feed_id}']").parent()
  sidebar_feed.replaceWith data

#-------------------------------------------------------
# Read a feed under a specific folder
#-------------------------------------------------------
Feedbunch.read_feed = (feed_id, folder_id) ->
  open_folder folder_id
  $("#feeds-#{folder_id} a[data-sidebar-feed][data-feed-id='#{feed_id}']").click()

#-------------------------------------------------------
# Mark a sidebar feed or folder link as active
#-------------------------------------------------------
Feedbunch.make_active = (feed_id, folder_id) ->
  $("#folders-list #folder-#{folder_id} a[data-feed-id='#{feed_id}']").parent().addClass "active"

#-------------------------------------------------------
# Insert a list of entries, replacing the old one (if any)
#-------------------------------------------------------
Feedbunch.insert_entries = (data) ->
  $("#feed-entries").html data

#-------------------------------------------------------
# Hide the "Loading" message
#-------------------------------------------------------
Feedbunch.hide_loading_message = ->
  $("#loading").addClass "hidden"

#-------------------------------------------------------
# Show the "Loading" message
#-------------------------------------------------------
Feedbunch.show_loading_message = ->
  $("#loading").removeClass "hidden"

#-------------------------------------------------------
# While loading entries hide the entries list,show "Loading" message and optionally show a spinner
#-------------------------------------------------------
Feedbunch.loading_entries = (feed)->
  Feedbunch.disable_buttons()
  Feedbunch.hide_entries()
  $("#start-info").addClass "hidden"
  Feedbunch.show_loading_message()
  if feed
    $(".icon-spinner", feed).addClass("icon-spin").removeClass "hidden"

#-------------------------------------------------------
# When entries have loaded hide the spinner and "Loading" message, show the entries list
#-------------------------------------------------------
Feedbunch.entries_loaded = (feed_id)->
  if feed_id
    $("#sidebar .icon-spin").addClass "hidden"
  $(".icon-spin").removeClass("icon-spin")
  Feedbunch.hide_loading_message()
  Feedbunch.show_entries()
  Feedbunch.enable_buttons()

#-------------------------------------------------------
# Hide the entries list
#-------------------------------------------------------
Feedbunch.hide_entries = ->
  $("#feed-entries").empty().addClass "hidden"

#-------------------------------------------------------
# Show the entries list
#-------------------------------------------------------
Feedbunch.show_entries = ->
  $("#feed-entries").removeClass "hidden"

#-------------------------------------------------------
# Hide the feed title
#-------------------------------------------------------
Feedbunch.hide_feed_title = ()->
  $("#feed-title a").text ""
  $("#feed-title").addClass "hidden"
  $("#feed-title a").attr "href", ""

#-------------------------------------------------------
# Show the "Start" page
#-------------------------------------------------------
Feedbunch.show_start_page = ()->
  $("#start-page").click()

#-------------------------------------------------------
# Disable the Refresh, Folder Management and Unsubscribe buttons
#-------------------------------------------------------
Feedbunch.disable_buttons = ->
  disable_entries_management_button()
  disable_folder_management_button()
  disable_unsubscribe_button()

#-------------------------------------------------------
# Enable and show the Refresh, Folder Management and Unsubscribe buttons
#-------------------------------------------------------
Feedbunch.enable_buttons = ->
  # Buttons are shown and enabled only if reading a single feed
  if Feedbunch.current_feed_id=="all"
    Feedbunch.hide_buttons()
  else
    enable_entries_management_button()
    enable_folder_management_button()
    enable_unsubscribe_button()

#-------------------------------------------------------
# Hide the Refresh, Folder Management and Unsubscribe buttons
#-------------------------------------------------------
Feedbunch.hide_buttons = ->
  hide_entries_management_button()
  hide_folder_management_button()
  hide_unsubscribe_button()

########################################################
# PRIVATE FUNCTIONS
########################################################

#-------------------------------------------------------
# Open a folder in the sidebar, if it's not already open
#-------------------------------------------------------
open_folder = (folder_id) ->
  $("#sidebar #feeds-#{folder_id}").not(".in").prev("a").click()

#-------------------------------------------------------
# Disable Entries Management button
#-------------------------------------------------------
disable_entries_management_button = ->
  $("#entries-management").addClass "disabled"

#-------------------------------------------------------
# Disable Folder Management button
#-------------------------------------------------------
disable_folder_management_button = ->
  $("#folder-management").addClass "disabled"

#-------------------------------------------------------
# Disable Unsubscribe button
#-------------------------------------------------------
disable_unsubscribe_button = ->
  $("#unsubscribe-feed").addClass "disabled"

#-------------------------------------------------------
# Enable and show the Entries Management button
#-------------------------------------------------------
enable_entries_management_button = ->
  $("#entries-management").removeClass("hidden").removeClass("disabled")

#-------------------------------------------------------
# Enable and show the Folder Management button
#-------------------------------------------------------
enable_folder_management_button = ->
  $("#folder-management").removeClass("hidden").removeClass("disabled")

#-------------------------------------------------------
# Enable and show the Unsubscribe button
#-------------------------------------------------------
enable_unsubscribe_button = ->
  $("#unsubscribe-feed").removeClass("hidden").removeClass("disabled")

#-------------------------------------------------------
# Hide Entries Management button
#-------------------------------------------------------
hide_entries_management_button = ->
  $("#entries-management").addClass("hidden").addClass "disabled"

#-------------------------------------------------------
# Hide Folder Management button
#-------------------------------------------------------
hide_folder_management_button = ->
  $("#folder-management").addClass("hidden").addClass "disabled"

#-------------------------------------------------------
# Hide Unsubscribe button
#-------------------------------------------------------
hide_unsubscribe_button = ->
  $("#unsubscribe-feed").addClass("hidden").addClass "disabled"