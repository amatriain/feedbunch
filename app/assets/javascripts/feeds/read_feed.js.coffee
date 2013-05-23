#= require ./alert_hiding
#= require ./shared_functions

window.Openreader ||= {}

$(document).ready ->

  ########################################################
  # EVENTS
  ########################################################

  #-------------------------------------------------------
  # Load current feed entries when clicking on a feed in the sidebar
  #-------------------------------------------------------
  $("body").on "click", "[data-sidebar-feed]", ->

    # Function to insert new entries in the list
    insert_entries = (entries, status, xhr) ->
      entries_loaded()
      enable_buttons()
      if status in ["error", "timeout", "abort", "parsererror"]
        if xhr.status == 404
          Openreader.alertTimedShowHide $("#no-entries")
        else
          Openreader.alertTimedShowHide $("#problem-loading")

    Openreader.current_feed_path = $(this).attr "data-feed-path"
    Openreader.current_feed_refresh_path = $(this).attr "data-refresh-path"
    Openreader.current_feed_id = $(this).attr "data-feed-id"
    Openreader.current_folder_id = $(this).attr "data-folder-id"
    Openreader.current_folder_id ||= "none"
    mark_folder_in_dropdown()
    show_feed_title this
    Openreader.loading_entries this

    # Load the entries via Ajax
    $("#feed-entries").load Openreader.current_feed_path, null, insert_entries

  ########################################################
  # COMMON FUNCTIONS
  ########################################################

  #-------------------------------------------------------
  # When entries have loaded hide the spinner and "Loading" message, show the entries list
  #-------------------------------------------------------
  entries_loaded = ()->
    $(".icon-spin").removeClass("icon-spin").addClass "hidden"
    Openreader.hide_loading_message()
    $("#feed-entries").removeClass "hidden"

  #-------------------------------------------------------
  # Show the feed title and link it to the feed URL
  #-------------------------------------------------------
  show_feed_title = (feed)->
    # Show the feed title
    feed_title = $(feed).attr "data-feed-title"
    $("#feed-title a").text feed_title
    $("#feed-title").removeClass "hidden"
    feed_url = $(feed).attr "data-feed-url"
    $("#feed-title a").attr("href", feed_url)

  #-------------------------------------------------------
  # Mark with a tick the current feed's folder in the dropdown
  #-------------------------------------------------------
  mark_folder_in_dropdown = ->
    $("#folder-management-dropdown a[data-folder-id] i.icon-ok").addClass "hidden"
    $("#folder-management-dropdown a[data-folder-id='#{Openreader.current_folder_id}'] i.icon-ok")
      .removeClass "hidden"

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

  #-------------------------------------------------------
  # Enable and show the Refresh, Folder Management and Unsubscribe buttons
  #-------------------------------------------------------
  enable_buttons = ->
    enable_refresh_button()
    # Unsubscribe and Folder Management buttons are shown and enabled only if reading a single feed
    if Openreader.current_feed_id=="all"
      hide_folder_management_button()
      hide_unsubscribe_button()
    else
      enable_folder_management_button()
      enable_unsubscribe_button()

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