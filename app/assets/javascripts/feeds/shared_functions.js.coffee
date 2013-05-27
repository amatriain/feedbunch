window.Openreader ||= {}

########################################################
# GLOBAL FUNCTIONS
########################################################

#-------------------------------------------------------
# Totally remove a folder from the sidebar and the dropdown
#-------------------------------------------------------
Openreader.remove_folder = (folder_id) ->
  $("#sidebar #folder-#{folder_id}").remove()
  $("#folder-management-dropdown a[data-folder-id='#{folder_id}']").parent().remove()

#-------------------------------------------------------
# Remove feed from all folders, except the All Subscriptions folder
#-------------------------------------------------------
Openreader.remove_feed_from_folders = (feed_id) ->
  $("[data-sidebar-feed][data-feed-id='#{feed_id}']").parent().each ->
    # Do not remove it from the "All Subscriptions" folder
    $(this).remove() if $(this).parent().attr("id") != "feeds-all"

#-------------------------------------------------------
# Insert feed in a folder in the sidebar
#-------------------------------------------------------
Openreader.insert_feed_in_folder = (feed_id, folder_id, feed_data) ->
  $("#folder-#{folder_id}-all-feeds").after feed_data
  if folder_id=="all"
    Openreader.update_folder_id feed_id, "none"
  else
    Openreader.update_folder_id feed_id, folder_id

#-------------------------------------------------------
# Update the data-folder-id attribute for all links to a feed in the sidebar
#-------------------------------------------------------
Openreader.update_folder_id = (feed_id, folder_id) ->
  $("[data-sidebar-feed][data-feed-id='#{feed_id}']").attr "data-folder-id", folder_id

#-------------------------------------------------------
# Update the count of unread entries in a folder by rewriting the "read all" link
#-------------------------------------------------------
Openreader.update_folder_entry_count = (folder_id, data) ->
  $("li#folder-#{folder_id}-all-feeds").replaceWith data

#-------------------------------------------------------
# Update the count of unread entries in a feed by rewriting its link in the sidebar. Optionally
# can set the feed CSS class as "active"
#-------------------------------------------------------
Openreader.update_feed_entry_count = (feed_id, data, active=false) ->
  sidebar_feed = $("[data-sidebar-feed][data-feed-id='#{feed_id}']").parent()
  sidebar_feed.replaceWith data
  if active
    sidebar_feed.addClass "active"

#-------------------------------------------------------
# Read a feed under a specific folder
#-------------------------------------------------------
Openreader.read_feed = (feed_id, folder_id) ->
  open_folder folder_id
  $("#feeds-#{folder_id} a[data-sidebar-feed][data-feed-id='#{feed_id}']").click()

#-------------------------------------------------------
# Insert a list of entries, replacing the old one (if any)
#-------------------------------------------------------
Openreader.insert_entries = (data) ->
  $("#feed-entries").html data

#-------------------------------------------------------
# Hide the "Loading" message
#-------------------------------------------------------
Openreader.hide_loading_message = ->
  $("#loading").addClass "hidden"

#-------------------------------------------------------
# Show the "Loading" message
#-------------------------------------------------------
Openreader.show_loading_message = ->
  $("#loading").removeClass "hidden"

#-------------------------------------------------------
# While loading entries hide the entries list,show "Loading" message and optionally show a spinner
#-------------------------------------------------------
Openreader.loading_entries = (feed)->
  Openreader.disable_buttons()
  Openreader.hide_entries()
  $("#start-info").addClass "hidden"
  Openreader.show_loading_message()
  if feed
    $(".icon-spinner", feed).addClass("icon-spin").removeClass "hidden"

#-------------------------------------------------------
# When entries have loaded hide the spinner and "Loading" message, show the entries list
#-------------------------------------------------------
Openreader.entries_loaded = (feed_id)->
  if feed_id
    $("#sidebar .icon-spin").addClass "hidden"
  $(".icon-spin").removeClass("icon-spin")
  Openreader.hide_loading_message()
  Openreader.show_entries()
  Openreader.enable_buttons()

#-------------------------------------------------------
# Hide the entries list
#-------------------------------------------------------
Openreader.hide_entries = ->
  $("#feed-entries").empty().addClass "hidden"

#-------------------------------------------------------
# Show the entries list
#-------------------------------------------------------
Openreader.show_entries = ->
  $("#feed-entries").removeClass "hidden"

#-------------------------------------------------------
# Hide the feed title
#-------------------------------------------------------
Openreader.hide_feed_title = ()->
  $("#feed-title a").text ""
  $("#feed-title").addClass "hidden"
  $("#feed-title a").attr "href", ""

#-------------------------------------------------------
# Show the "Start" page
#-------------------------------------------------------
Openreader.show_start_page = ()->
  $("#start-page").click()

#-------------------------------------------------------
# Disable the Refresh, Folder Management and Unsubscribe buttons
#-------------------------------------------------------
Openreader.disable_buttons = ->
  disable_read_all_button()
  disable_refresh_button()
  disable_folder_management_button()
  disable_unsubscribe_button()

#-------------------------------------------------------
# Enable and show the Refresh, Folder Management and Unsubscribe buttons
#-------------------------------------------------------
Openreader.enable_buttons = ->
  # Buttons are shown and enabled only if reading a single feed
  if Openreader.current_feed_id=="all"
    Openreader.hide_buttons()
  else
    enable_read_all_button()
    enable_refresh_button()
    enable_folder_management_button()
    enable_unsubscribe_button()

#-------------------------------------------------------
# Hide the Refresh, Folder Management and Unsubscribe buttons
#-------------------------------------------------------
Openreader.hide_buttons = ->
  hide_read_all_button()
  hide_refresh_button()
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
# Disable Read All button
#-------------------------------------------------------
disable_read_all_button = ->
  $("#read-all-button").addClass "disabled"

#-------------------------------------------------------
# Disable Refresh button
#-------------------------------------------------------
disable_refresh_button = ->
  $("#refresh-feed").addClass "disabled"

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
# Enable and show the Read All button
#-------------------------------------------------------
enable_read_all_button = ->
  $("#read-all-button").removeClass("hidden").removeClass("disabled")

#-------------------------------------------------------
# Enable and show the Refresh button
#-------------------------------------------------------
enable_refresh_button = ->
  $("#refresh-feed").removeClass("hidden").removeClass("disabled")

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
# Hide Read All button
#-------------------------------------------------------
hide_read_all_button = ->
  $("#read-all-button").addClass("hidden").addClass "disabled"

#-------------------------------------------------------
# Hide Refresh button
#-------------------------------------------------------
hide_refresh_button = ->
  $("#refresh-feed").addClass("hidden").addClass "disabled"

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