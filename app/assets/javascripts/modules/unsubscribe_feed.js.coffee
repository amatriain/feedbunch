#= require ./alert_hiding
#= require ./shared_functions

$(document).ready ->

  ########################################################
  # EVENTS
  ########################################################

  #-------------------------------------------------------
  # Show unsubscribe confirmation popup (only if button enabled)
  #-------------------------------------------------------
  $("body").on "click", "#unsubscribe-feed", ->
    if $(this).hasClass("disabled") == false
      show_popup()

  #-------------------------------------------------------
  # Unsubscribe from feed via Ajax
  #-------------------------------------------------------
  $("#unsubscribe-submit").on "click", ->
    close_popup()

    # Function to handle result returned by the server
    unsubscribe_result = (data, status, xhr) ->
      remove_feed()
      Feedbunch.update_folder_entry_count "all", data["all_subscriptions"]["sidebar_read_all"]
      if data["old_folder"]
        if data["old_folder"]["deleted"]
          Feedbunch.remove_folder data["old_folder"]["id"]
        else
          Feedbunch.update_folder_entry_count data["old_folder"]["id"], data["old_folder"]["sidebar_read_all"]

    $.post(Feedbunch.current_feed_path, {"_method":"delete"}, unsubscribe_result, 'json')
      .fail ->
        Feedbunch.alertTimedShowHide $("#problem-unsubscribing")

    Feedbunch.show_start_page()

  ########################################################
  # COMMON FUNCTIONS
  ########################################################

  #-------------------------------------------------------
  # Remove feed from the sidebar
  #-------------------------------------------------------
  remove_feed = ->
    $("[data-sidebar-feed][data-feed-id=#{Feedbunch.current_feed_id}]").parent().remove()

  #-------------------------------------------------------
  # Show modal popup
  #-------------------------------------------------------
  show_popup = ->
    $("#unsubscribe-feed-popup").modal "show" if $(this).hasClass("disabled")==false

  #-------------------------------------------------------
  # Close modal popup
  #-------------------------------------------------------
  close_popup = ->
    $("#unsubscribe-feed-popup").modal 'hide'