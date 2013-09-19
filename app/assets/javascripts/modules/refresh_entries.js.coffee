#= require ./alert_hiding
#= require ./shared_functions

$(document).ready ->

  ########################################################
  # EVENTS
  ########################################################

  #-------------------------------------------------------
  # Load new feed entries when clicking on the Refresh button (only if button enabled)
  #-------------------------------------------------------
  ###
  $("body").on "click", "#refresh-feed", ->
    if $(this).hasClass("disabled") == false
      # Only refresh if the global variable stores a feed refresh path
      if Feedbunch.current_feed_path?.length
        start_icon_animation()
        Feedbunch.loading_entries()

        # Function to insert new entries in the list
        entries_received = (data, status, xhr) ->
          Feedbunch.update_folder_entry_count "all", data["folder_all"]["sidebar_read_all"]
          Feedbunch.update_feed_entry_count data["feed"]["id"], data["feed"]["sidebar"]
          Feedbunch.read_feed data["feed"]["id"], Feedbunch.current_folder_id
          if data["folder"]
            Feedbunch.update_folder_entry_count data["folder"]["id"], data["folder"]["sidebar_read_all"]

        $.post(Feedbunch.current_feed_path, {"_method":"patch"}, entries_received, 'json')
          .fail ->
            Feedbunch.hide_loading_message()
            stop_icon_animation()
            Feedbunch.alertTimedShowHide $("#problem-refreshing")
  ###

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