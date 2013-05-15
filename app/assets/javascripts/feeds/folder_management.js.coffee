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
      if xhr.status == 205
        # If the return status is 205, remove the folder (there are no more feeds in it)
        old_folder_id = find_feed_folder feed_id
        remove_folder old_folder_id
      else
        # If the return status is 204, remove the feed from the folder but not the folder itself (it has more feeds)
        remove_feed_from_folders feed_id
      update_folder_id feed_id, "none"
      open_folder "all"
      read_feed feed_id, "all"


    $.post(delete_folder_path, {"_method":"delete", feed_id: feed_id}, remove_folder_result)
      .fail ->
        Application.alertTimedShowHide $("#problem-folder-management")

  #-------------------------------------------------------
  # Show "New folder" popup when clicking on New Folder in the dropdown
  #-------------------------------------------------------
  $("a[data-new-folder-path]").on "click", ->
    $("#new-folder-popup").modal "show"

  #-------------------------------------------------------
  # Submit the "New Folder" form when clicking on the "Add" button
  #-------------------------------------------------------
  $("#new-folder-submit").on "click", ->
    $("#form-new-folder").submit()

  #-------------------------------------------------------
  # Submit the "New Folder" form via Ajax
  #-------------------------------------------------------
  $("#form-new-folder").on "submit", ->
    feed_id = $("#new_folder_feed_id", this).val()

    # Function to handle result returned by the server
    new_folder_result = (data, status, xhr) ->
      if xhr.status == 304
        Application.alertTimedShowHide $("#folder-already-exists")
      else
        remove_feed_from_folders feed_id
        add_folder data
        update_folder_id feed_id, data["folder_id"]
        open_folder data["folder_id"]
        read_feed feed_id, data["folder_id"]

    # If the user has written something in the form, POST the value via ajax
    if $("#new_folder_title").val()
      form_url = $("#form-new-folder").attr "action"
      post_data = $(this).serialize()
      $.post(form_url, post_data, new_folder_result, 'json')
        .fail ->
          Application.alertTimedShowHide $("#problem-new-folder")

    # Clean textfield and close modal
    $("#new_folder_title").val('')
    $("#new-folder-popup").modal 'hide'

    # prevent default form submit
    return false

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
    $("#feeds-#{folder_id} a[data-sidebar-feed][data-feed-id='#{feed_id}']").click()

  #-------------------------------------------------------
  # Find out the folder to which a feed currently belongs
  #-------------------------------------------------------
  find_feed_folder = (feed_id) ->
    return $("#sidebar a[data-sidebar-feed][data-feed-id='#{feed_id}']").attr "data-folder-id"

  #-------------------------------------------------------
  # Totally remove a folder from the sidebar and the dropdown
  #-------------------------------------------------------
  remove_folder = (folder_id) ->
    $("#sidebar #folder-#{folder_id}").remove()
    $("#folder-management-dropdown a[data-folder-id='#{folder_id}']").parent().remove()

  #-------------------------------------------------------
  # Add a new folder to the sidebar and the dropdown
  #-------------------------------------------------------
  add_folder = (folder_data) ->
    $("#sidebar #folders-list").append folder_data["sidebar_folder"]
    $("#folder-management-dropdown ul.dropdown-menu li.divider").first().after folder_data["dropdown_folder"]
