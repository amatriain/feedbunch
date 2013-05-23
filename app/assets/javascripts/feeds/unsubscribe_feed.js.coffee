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
    show_popup()

  #-------------------------------------------------------
  # Unsubscribe from feed via Ajax
  #-------------------------------------------------------
  $("#unsubscribe-submit").on "click", ->
    close_popup()

    # Function to handle result returned by the server
    unsubscribe_result = (data, status, xhr) ->
      remove_feed()
      # If the feed was in a folder which is now empty, remove it
      if xhr.status == 205
        Openreader.remove_folder Openreader.current_folder_id

    $.post(Openreader.current_feed_path, {"_method":"delete"}, unsubscribe_result)
      .fail ->
        Openreader.alertTimedShowHide $("#problem-unsubscribing")

    Openreader.show_start_page()

  ########################################################
  # COMMON FUNCTIONS
  ########################################################

  #-------------------------------------------------------
  # Remove feed from the sidebar
  #-------------------------------------------------------
  remove_feed = ->
    $("[data-sidebar-feed][data-feed-id=#{Openreader.current_feed_id}]").parent().remove()

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