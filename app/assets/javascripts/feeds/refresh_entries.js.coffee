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
        Openreader.show_loading_message()
        Openreader.disable_buttons()

        # Function to insert new entries in the list
        insert_entries = (entries, status, xhr) ->
          stop_icon_animation()
          Openreader.hide_loading_message()
          Openreader.enable_buttons()
          if status in ["error", "timeout", "abort", "parsererror"]
            Openreader.alertTimedShowHide $("#problem-refreshing")

        $("#feed-entries").empty().load Openreader.current_feed_refresh_path, null, insert_entries

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