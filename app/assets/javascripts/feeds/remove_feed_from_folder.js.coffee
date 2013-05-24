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
          Openreader.remove_folder data["old_folder"]["id"]
        else
          Openreader.remove_feed_from_folders Openreader.current_feed_id
          Openreader.update_folder_entry_count data["old_folder"]["id"], data["old_folder"]["sidebar_read_all"]
        Openreader.update_folder_id Openreader.current_feed_id, "none"
        Openreader.read_feed Openreader.current_feed_id, "all"

    $.post(delete_folder_path, {"_method":"delete", feed_id: Openreader.current_feed_id}, remove_folder_result)
      .fail ->
        Openreader.alertTimedShowHide $("#problem-folder-management")


  ########################################################
  # COMMON FUNCTIONS
  ########################################################

