#= require ./alert_hiding

$(document).ready ->

  #-------------------------------------------------------
  # Load current feed entries when clicking on a feed in the sidebar
  #-------------------------------------------------------
  $("body").on "click", "[data-sidebar-feed]", ->

    # Function to insert new entries in the list
    insert_entries = (entries, status, xhr) ->
      $(".icon-spin").removeClass("icon-spin").addClass "hidden"
      $("#loading").addClass "hidden"
      $("#feed-entries").removeClass "hidden"
      # Show and enable Refresh button
      $("#refresh-feed").removeClass("hidden").removeClass("disabled")
      # Unsubscribe and Folder Management buttons are shown and enabled only if reading a single feed
      if feed_id=="all"
        $("#unsubscribe-feed").addClass("hidden").addClass("disabled")
        $("#folder-management").addClass("hidden").addClass("disabled")
      else
        $("#unsubscribe-feed").removeClass("hidden").removeClass("disabled")
        $("#folder-management").removeClass("hidden").removeClass("disabled")

      if status in ["error", "timeout", "abort", "parsererror"]
        if xhr.status == 404
          Application.alertTimedShowHide $("#no-entries")
        else
          Application.alertTimedShowHide $("#problem-loading")

    feed_path = $(this).attr "data-feed-path"
    refresh_path = $(this).attr "data-refresh-path"
    feed_id = $(this).attr "data-feed-id"

    # The refresh button now refreshes this feed; it's disabled while the feed loads
    $("#refresh-feed").attr("data-refresh-feed", refresh_path).addClass "disabled"

    # The unsubscribe button now unsubscribes from this feed; it's disabled while the feed loads
    $("#unsubscribe-feed").attr("data-unsubscribe-feed", feed_id).attr("data-unsubscribe-path", feed_path).addClass "disabled"

    # The Folder Management button is disabled while the feed loads
    $("#folder-management").addClass "disabled"

    folder_id = $(this).attr "data-folder-id"
    folder_id ||= "none"
    # Mark with a tick the folder in the dropdown
    $("#folder-management-dropdown a[data-folder-id] i.icon-ok").addClass "hidden"
    $("#folder-management-dropdown a[data-folder-id='#{folder_id}'] i.icon-ok").removeClass "hidden"
    # Clicking on the dropdown changes folder association for the current feed
    $("#folder-management-dropdown a").attr("data-feed-id", feed_id)
    # Creating a new folder adds this feed to it
    $("#new_folder_feed_id").val(feed_id)

    # Show the feed title
    feed_title = $(this).attr "data-feed-title"
    $("#feed-title a").text feed_title
    $("#feed-title").removeClass "hidden"

    # The feed title links to the feed url
    feed_url = $(this).attr "data-feed-url"
    $("#feed-title a").attr("href", feed_url)

    # Empty the entries list before loading
    $("#feed-entries").empty().addClass "hidden"

    # Hide the start page
    $("#start-info").addClass "hidden"

    # Show "loading" message
    $("#loading").removeClass "hidden"

    # Show a spinning icon while loading
    $(".icon-spinner", this).addClass("icon-spin").removeClass "hidden"

    # Load the entries via Ajax
    $("#feed-entries").load feed_path, null, insert_entries