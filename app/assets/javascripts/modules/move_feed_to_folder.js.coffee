#= require ./alert_hiding
#= require ./shared_functions

$(document).ready ->

  ########################################################
  # EVENTS
  ########################################################

  #-------------------------------------------------------
  # Add feed to folder clicking on a folder in the dropdown
  #-------------------------------------------------------
  $("body").on "click", "a[data-folder-update-path]", ->
    update_folder_path = $(this).attr "data-folder-update-path"
    folder_id = $(this).attr("data-folder-id")

    # Function to handle result returned by the server
    update_folder_result = (data, status, xhr) ->
      if xhr.status == 304
        Feedbunch.alertTimedShowHide $("#already-in-folder")
      else
        if data["old_folder"]
          if data["old_folder"]["deleted"]
            Feedbunch.remove_folder data["old_folder"]["id"]
          else
            Feedbunch.remove_feed_from_folders Feedbunch.current_feed_id
            Feedbunch.update_folder_entry_count data["old_folder"]["id"], data["old_folder"]["sidebar_read_all"]
        Feedbunch.insert_feed_in_folder Feedbunch.current_feed_id, folder_id, data["new_folder"]["sidebar_feed"]
        Feedbunch.update_folder_entry_count data["new_folder"]["id"], data["new_folder"]["sidebar_read_all"]
        Feedbunch.read_feed Feedbunch.current_feed_id, folder_id

    $.post(update_folder_path, {"_method":"patch", folder: {feed_id: Feedbunch.current_feed_id}}, update_folder_result, "json")
      .fail ->
        Feedbunch.alertTimedShowHide $("#problem-folder-management")

  #-------------------------------------------------------
  # Show "New folder" popup when clicking on New Folder in the dropdown
  #-------------------------------------------------------
  $("body").on "click", "a[data-new-folder-path]", ->
    show_popup()

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
        Feedbunch.alertTimedShowHide $("#folder-already-exists")
      else
        if data["old_folder"]
          if data["old_folder"]["deleted"]
            Feedbunch.remove_folder data["old_folder"]["id"]
          else
            Feedbunch.remove_feed_from_folders Feedbunch.current_feed_id
            Feedbunch.update_folder_entry_count data["old_folder"]["id"], data["old_folder"]["sidebar_read_all"]
        add_folder data["new_folder"]
        new_folder_id = data["new_folder"]["id"]
        Feedbunch.update_folder_id Feedbunch.current_feed_id, new_folder_id
        Feedbunch.read_feed Feedbunch.current_feed_id, new_folder_id

    # If the user has written something in the form, POST the value via ajax
    if $("#new_folder_title").val()
      form_url = $("#form-new-folder").attr "action"
      folder_title = $("#new_folder_title").val()
      $.post(form_url, folder: {feed_id: Feedbunch.current_feed_id, title: folder_title}, new_folder_result, 'json')
        .fail ->
          Feedbunch.alertTimedShowHide $("#problem-new-folder")

    close_popup()

    # prevent default form submit
    return false

  ########################################################
  # COMMON FUNCTIONS
  ########################################################

  #-------------------------------------------------------
  # Add a new folder to the sidebar and the dropdown
  #-------------------------------------------------------
  add_folder = (folder_data) ->
    $("#sidebar #folders-list").append folder_data["sidebar"]
    $("#folder-management-dropdown ul.dropdown-menu li.divider").first().after folder_data["dropdown"]

  #-------------------------------------------------------
  # Show modal popup
  #-------------------------------------------------------
  show_popup = ->
    $("#new-folder-popup").modal "show"

  #-------------------------------------------------------
  # Clean textfield and close modal popup
  #-------------------------------------------------------
  close_popup = ->
    $("#new_folder_title").val('')
    $("#new-folder-popup").modal 'hide'
