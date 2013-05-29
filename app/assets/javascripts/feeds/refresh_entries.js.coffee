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
          Openreader.update_folder_entry_count "all", data["folder_all"]["sidebar_read_all"]
          Openreader.update_feed_entry_count data["feed"]["id"], data["feed"]["sidebar"]
          Openreader.read_feed data["feed"]["id"], Openreader.current_folder_id
          if data["folder"]
            Openreader.update_folder_entry_count data["folder"]["id"], data["folder"]["sidebar_read_all"]

        $.get(Openreader.current_feed_refresh_path, null, entries_received, 'json')
          .fail ->
            Openreader.hide_loading_message()
            stop_icon_animation()
            Openreader.alertTimedShowHide $("#problem-refreshing")

  ########################################################
  # COMMON FUNCTIONS
  ########################################################

  #-------------------------------------------------------
  # Start animation of the refresh icon in the button
  #-------------------------------------------------------
  start_icon_animation = ->
    $("#refresh-feed i.icon-repeat").addClass "icon-spin"

  #-------------------------------------------------------
  # Stop animation of the refresh icon in the button
  #-------------------------------------------------------
  stop_icon_animation = ->
    $("#refresh-feed i.icon-repeat").removeClass "icon-spin"