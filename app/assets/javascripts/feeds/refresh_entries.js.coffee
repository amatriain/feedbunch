#= require ./alert_hiding

$(document).ready ->

  #-------------------------------------------------------
  # Load new feed entries when clicking on the Refresh button (only if button enabled)
  #-------------------------------------------------------
  $("body").on "click", "#refresh-feed", ->
    if $(this).hasClass("disabled") == false
      # Only refresh if the global variable stores a feed refresh path
      if Openreader.current_feed_refresh_path?.length
        $("> i.icon-repeat", this).addClass "icon-spin"
        # Show "loading" message
        $("#loading").removeClass "hidden"
        $(this).addClass "disabled"
        $("#unsubscribe-feed").addClass "disabled"
        $("#folder-management").addClass "disabled"

        # Function to insert new entries in the list
        insert_entries = (entries, status, xhr) ->
          $("#refresh-feed > i.icon-repeat").removeClass "icon-spin"
          $("#loading").addClass "hidden"
          $("#refresh-feed").removeClass "disabled"
          $("#unsubscribe-feed").removeClass "disabled"
          $("#folder-management").removeClass "disabled"
          if status in ["error", "timeout", "abort", "parsererror"]
            Openreader.alertTimedShowHide $("#problem-refreshing")

        $("#feed-entries").empty().load Openreader.current_feed_refresh_path, null, insert_entries