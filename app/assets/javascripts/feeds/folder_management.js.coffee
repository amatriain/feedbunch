#= require ./alert_hiding

$(document).ready ->

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
        # Remove the feed from its old folder, if any
        count = $("[data-sidebar-feed][data-feed-id='#{feed_id}']").parent().each ->
          # Do not remove it from the "All Subscriptions" folder
          $(this).remove() if $(this).parent().attr("id") != "feeds-all"
        # Update the data-folder-id of the feed links in the sidebar to the new folder id
        $("[data-sidebar-feed][data-feed-id='#{feed_id}']").attr "data-folder-id", folder_id
        # Insert the new feed in the folder
        $("#folder-#{folder_id}-all-feeds").after data
        # Open the folder if not already open
        $("#sidebar #feeds-#{folder_id}").not(".in").prev("a").click()
        # Select the feed in its new folder
        $("#folder-#{folder_id}-all-feeds").next().find("a").click()

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
      # Remove the feed from its old folder, if any
      count = $("[data-sidebar-feed][data-feed-id='#{feed_id}']").parent().each ->
        # Do not remove it from the "All Subscriptions" folder
        $(this).remove() if $(this).parent().attr("id") != "feeds-all"
      # Remove the data-folder-id of the feed links in the sidebar
      $("[data-sidebar-feed][data-feed-id='#{feed_id}']").removeAttr "data-folder-id"
      # Open the All Subscriptions folder if not already open
      $("#sidebar #feeds-all").not(".in").prev("a").click()
      # Select the feed in its new folder
      $("#sidebar #feeds-all a[data-feed-id='#{feed_id}']").click()

    $.post(delete_folder_path, {"_method":"delete", feed_id: feed_id}, remove_folder_result)
      .fail ->
        Application.alertTimedShowHide $("#problem-unsubscribing")