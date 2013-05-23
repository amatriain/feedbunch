#= require ./alert_hiding
#= require ./shared_functions

$(document).ready ->

  #-------------------------------------------------------
  # Show unsubscribe confirmation popup (only if button enabled)
  #-------------------------------------------------------
  $("body").on "click", "#unsubscribe-feed", ->
    $("#unsubscribe-feed-popup").modal "show" if $(this).hasClass("disabled")==false

  #-------------------------------------------------------
  # Unsubscribe from feed via Ajax
  #-------------------------------------------------------
  $("#unsubscribe-submit").on "click", ->
    $("#unsubscribe-feed-popup").modal 'hide'

    # Function to handle result returned by the server
    unsubscribe_result = (data, status, xhr) ->
      # Remove the feed from the sidebar
      $("[data-sidebar-feed][data-feed-id=#{Openreader.current_feed_id}]").parent().remove()
      # If the feed was in a folder which is not empty, remove it
      if xhr.status == 205
        Openreader.remove_folder Openreader.current_folder_id

    $.post(Openreader.current_feed_path, {"_method":"delete"}, unsubscribe_result)
      .fail ->
        Openreader.alertTimedShowHide $("#problem-unsubscribing")

    Openreader.show_start_page()