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
    unsubscribe_path = $("#unsubscribe-feed").attr("data-unsubscribe-path")
    unsubscribe_feed = $("#unsubscribe-feed").attr("data-unsubscribe-feed")
    unsubscribe_folder = $("#unsubscribe-feed").attr("data-unsubscribe-folder")

    # Function to handle result returned by the server
    unsubscribe_result = (data, status, xhr) ->
      # Remove the feed from the sidebar
      $("[data-sidebar-feed][data-feed-id=#{unsubscribe_feed}]").parent().remove()
      # If the feed was in a folder which is not empty, remove it
      if xhr.status == 205
        Application.remove_folder unsubscribe_folder

    $.post(unsubscribe_path, {"_method":"delete"}, unsubscribe_result)
      .fail ->
        Application.alertTimedShowHide $("#problem-unsubscribing")

    # Show the start page
    $("#start-page").click()