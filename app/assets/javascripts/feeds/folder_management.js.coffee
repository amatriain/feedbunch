#= require ./alert_hiding

$(document).ready ->

  ########################################################
  # EVENTS
  ########################################################

  #-------------------------------------------------------
  # Associate feed with folder clicking on a folder in the dropdown
  #-------------------------------------------------------
  $("a[data-folder-update-path]").on "click", ->
    update_folder_path = $(this).attr "data-folder-update-path"
    feed_id = $(this).attr("data-feed-id")
    folder_id = $(this).attr("data-folder-id")

    # Function to handle result returned by the server
    update_folder_result = (data, status, xhr) ->
      if xhr.status == 304
        Application.alertTimedShowHide $("#already-in-folder")
      else
        remove_feed_from_folders feed_id
        update_folder_id feed_id, folder_id
        insert_feed_in_folder folder_id, data
        open_folder folder_id
        read_feed feed_id, folder_id

    $.post(update_folder_path, {"_method":"put", feed_id: feed_id}, update_folder_result)
      .fail ->
        Application.alertTimedShowHide $("#problem-folder-management")

  #-------------------------------------------------------
  # Remove feed from folders clicking on "None" in the dropdown
  #-------------------------------------------------------
  $("a[data-folder-remove-path]").on "click", ->
    delete_folder_path = $(this).attr "data-folder-remove-path"
    feed_id = $(this).attr("data-feed-id")

    # Function to handle result returned by the server
    remove_folder_result = (data, status, xhr) ->
      remove_feed_from_folders feed_id
      update_folder_id feed_id, "none"
      open_folder "all"
      read_feed feed_id, "all"

    $.post(delete_folder_path, {"_method":"delete", feed_id: feed_id}, remove_folder_result)
      .fail ->
        Application.alertTimedShowHide $("#problem-unsubscribing")


  ########################################################
  # COMMON FUNCTIONS
  ########################################################

  #-------------------------------------------------------
  # Remove feed from all folders, except the All Subscriptions folder
  #-------------------------------------------------------
  remove_feed_from_folders = (feed_id) ->
    $("[data-sidebar-feed][data-feed-id='#{feed_id}']").parent().each ->
      # Do not remove it from the "All Subscriptions" folder
      $(this).remove() if $(this).parent().attr("id") != "feeds-all"

  #-------------------------------------------------------
  # Insert feed in a folder in the sidebar
  #-------------------------------------------------------
  insert_feed_in_folder = (folder_id, feed_html) ->
    $("#folder-#{folder_id}-all-feeds").after feed_html

  #-------------------------------------------------------
  # Update the data-folder-id attribute for all links to a feed in the sidebar
  #-------------------------------------------------------
  update_folder_id = (feed_id, folder_id) ->
    $("[data-sidebar-feed][data-feed-id='#{feed_id}']").attr "data-folder-id", folder_id

  #-------------------------------------------------------
  # Open a folder in the sidebar, if it's not already open
  #-------------------------------------------------------
  open_folder = (folder_id) ->
    $("#sidebar #feeds-#{folder_id}").not(".in").prev("a").click()

  #-------------------------------------------------------
  # Read a feed under a specific folder
  #-------------------------------------------------------
  read_feed = (feed_id, folder_id) ->
    $("#folder-#{folder_id}-all-feeds a[data-sidebar-feed][data-feed-id='#{feed_id}']").click()