$(document).ready ->

  #-------------------------------------------------------
  # Show the start page when clicking on the "Start" link
  #-------------------------------------------------------
  $("#start-page").on "click", ->
    # Hide feed entries, title, and buttons
    $("#feed-entries").empty().addClass "hidden"
    $("#feed-title a").text ""
    $("#feed-title").addClass "hidden"
    $("#unsubscribe-feed").addClass("hidden").addClass("disabled")
    $("#refresh-feed").addClass("hidden").addClass("disabled")
    $("#folder-management").addClass("hidden").addClass("disabled")
    # Show the start page
    $("#start-info").removeClass "hidden"