#= require ./alert_hiding
#= require ./shared_functions

$(document).ready ->

  ########################################################
  # EVENTS
  ########################################################

  #-------------------------------------------------------
  # Remove feed from folders clicking on "None" in the dropdown
  #-------------------------------------------------------
  $("body").on "click", "a[data-folder-remove-path]", ->
    delete_folder_path = $(this).attr "data-folder-remove-path"

    # Function to handle result returned by the server
    remove_folder_result = (data, status, xhr) ->
      if data["old_folder"]
        if data["old_folder"]["deleted"]
          Feedbunch.remove_folder data["old_folder"]["id"]
        else
          Feedbunch.remove_feed_from_folders Feedbunch.current_feed_id
          Feedbunch.update_folder_entry_count data["old_folder"]["id"], data["old_folder"]["sidebar_read_all"]
        Feedbunch.update_folder_id Feedbunch.current_feed_id, "none"
        Feedbunch.read_feed Feedbunch.current_feed_id, "all"

    $.post(delete_folder_path, {"_method":"delete", folder: {feed_id: Feedbunch.current_feed_id}}, remove_folder_result)
      .fail ->
        Feedbunch.alertTimedShowHide $("#problem-folder-management")


  ########################################################
  # COMMON FUNCTIONS
  ########################################################

