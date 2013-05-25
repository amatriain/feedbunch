#= require ./alert_hiding
#= require ./shared_functions

$(document).ready ->

  ########################################################
  # EVENTS
  ########################################################

  #-------------------------------------------------------
  # Load new feed entries when clicking on the Refresh button (only if button enabled)
  #-------------------------------------------------------
  $("body").on "click", "#refresh-feed", ->
    if $(this).hasClass("disabled") == false
      # Only refresh if the global variable stores a feed refresh path
      if Openreader.current_feed_refresh_path?.length
        start_icon_animation()
        Openreader.loading_entries()

        # Function to insert new entries in the list
        entries_received = (data, status, xhr) ->
          Openreader.entries_loaded()
          Openreader.insert_entries data["feed"]["entries"]
          Openreader.update_feed_entry_count data["feed"]["id"], data["feed"]["sidebar"], true
          Openreader.update_folder_entry_count "all", data["folder_all"]["sidebar_read_all"]
          if data["folder"]
            Openreader.update_folder_entry_count data["folder"]["id"], data["folder"]["sidebar_read_all"]

        $.get(Openreader.current_feed_refresh_path, null, entries_received, 'json')
          .fail ->
            Openreader.hide_loading_message()
            Openreader.alertTimedShowHide $("#problem-refreshing")

  ########################################################
  # COMMON FUNCTIONS
  ########################################################

  #-------------------------------------------------------
  # Start animation of the refresh icon in the button
  #-------------------------------------------------------
  start_icon_animation = ->
    $("#refresh-feed i.icon-repeat").addClass "icon-spin"