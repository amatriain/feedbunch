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
      if xhr.status == 205
        # If the return status is 205, remove the folder (there are no more feeds in it)
        Openreader.remove_folder Openreader.current_folder_id
      else
        # If the return status is 204, remove the feed from the folder but not the folder itself (it has more feeds)
        Openreader.remove_feed_from_folders Openreader.current_feed_id
      Openreader.update_folder_id Openreader.current_feed_id, "none"
      Openreader.read_feed Openreader.current_feed_id, "all"


    $.post(delete_folder_path, {"_method":"delete", feed_id: Openreader.current_feed_id}, remove_folder_result)
      .fail ->
        Openreader.alertTimedShowHide $("#problem-folder-management")


  ########################################################
  # COMMON FUNCTIONS
  ########################################################

