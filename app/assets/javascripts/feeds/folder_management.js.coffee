#= require ./alert_hiding
#= require ./shared_functions

$(document).ready ->

  ########################################################
  # EVENTS
  ########################################################

  #-------------------------------------------------------
  # Associate feed with folder clicking on a folder in the dropdown
  #-------------------------------------------------------
  $("body").on "click", "a[data-folder-update-path]", ->
    update_folder_path = $(this).attr "data-folder-update-path"
    folder_id = $(this).attr("data-folder-id")

    # Function to handle result returned by the server
    update_folder_result = (data, status, xhr) ->
      if xhr.status == 304
        Openreader.alertTimedShowHide $("#already-in-folder")
      else
        if data["old_folder"]
          if data["old_folder"]["empty"]
            Openreader.remove_folder data["old_folder"]["id"]
          else
            remove_feed_from_folders Openreader.current_feed_id
        Openreader.insert_feed_in_folder Openreader.current_feed_id, folder_id, data["new_folder"]["sidebar"]
        Openreader.read_feed Openreader.current_feed_id, folder_id

    $.post(update_folder_path, {"_method":"put", feed_id: Openreader.current_feed_id}, update_folder_result, "json")
      .fail ->
        Openreader.alertTimedShowHide $("#problem-folder-management")

  #-------------------------------------------------------
  # Remove feed from folders clicking on "None" in the dropdown
  #-------------------------------------------------------
  $("body").on "click", "a[data-folder-remove-path]", ->
    delete_folder_path = $(this).attr "data-folder-remove-path"

    # Function to handle result returned by the server
    remove_folder_result = (data, status, xhr) ->
      if xhr.status == 205
        # If the return status is 205, remove the folder (there are no more feeds in it)
        old_folder_id = find_feed_folder Openreader.current_feed_id
        Openreader.remove_folder old_folder_id
      else
        # If the return status is 204, remove the feed from the folder but not the folder itself (it has more feeds)
        remove_feed_from_folders Openreader.current_feed_id
      Openreader.update_folder_id Openreader.current_feed_id, "none"
      Openreader.read_feed Openreader.current_feed_id, "all"


    $.post(delete_folder_path, {"_method":"delete", feed_id: Openreader.current_feed_id}, remove_folder_result)
      .fail ->
        Openreader.alertTimedShowHide $("#problem-folder-management")

  #-------------------------------------------------------
  # Show "New folder" popup when clicking on New Folder in the dropdown
  #-------------------------------------------------------
  $("body").on "click", "a[data-new-folder-path]", ->
    $("#new-folder-popup").modal "show"

  #-------------------------------------------------------
  # Submit the "New Folder" form when clicking on the "Add" button
  #-------------------------------------------------------
  $("body").on "click", "#new-folder-submit", ->
    $("#form-new-folder").submit()

  #-------------------------------------------------------
  # Submit the "New Folder" form via Ajax
  #-------------------------------------------------------
  $("body").on "submit", "#form-new-folder", ->
    # Function to handle result returned by the server
    new_folder_result = (data, status, xhr) ->
      if xhr.status == 304
        Openreader.alertTimedShowHide $("#folder-already-exists")
      else
        if data["old_folder"]
          if data["old_folder"]["empty"]
            Openreader.remove_folder data["old_folder"]["id"]
          else
            remove_feed_from_folders Openreader.current_feed_id
        add_folder data["new_folder"]
        new_folder_id = data["new_folder"]["id"]
        Openreader.update_folder_id Openreader.current_feed_id, new_folder_id
        Openreader.read_feed Openreader.current_feed_id, new_folder_id

    # If the user has written something in the form, POST the value via ajax
    if $("#new_folder_title").val()
      form_url = $("#form-new-folder").attr "action"
      # Set the current folder id in a hidden field, to be sent with the POST
      $("#new_folder_feed_id", this).val(Openreader.current_feed_id)
      post_data = $(this).serialize()
      $.post(form_url, post_data, new_folder_result, 'json')
        .fail ->
          Openreader.alertTimedShowHide $("#problem-new-folder")

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
  # Find out the folder to which a feed currently belongs
  #-------------------------------------------------------
  find_feed_folder = (feed_id) ->
    return $("#sidebar a[data-sidebar-feed][data-feed-id='#{feed_id}']").attr "data-folder-id"

  #-------------------------------------------------------
  # Add a new folder to the sidebar and the dropdown
  #-------------------------------------------------------
  add_folder = (folder_data) ->
    $("#sidebar #folders-list").append folder_data["sidebar"]
    $("#folder-management-dropdown ul.dropdown-menu li.divider").first().after folder_data["dropdown"]
