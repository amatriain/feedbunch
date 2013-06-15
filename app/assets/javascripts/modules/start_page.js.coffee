#= require ./alert_hiding
#= require ./shared_functions

$(document).ready ->

  ########################################################
  # EVENTS
  ########################################################

  #-------------------------------------------------------
  # Show the start page when clicking on the "Start" link
  #-------------------------------------------------------
  $("body").on "click", "#start-page", ->
    Openreader.hide_entries()
    Openreader.hide_feed_title()
    Openreader.hide_loading_message()
    Openreader.hide_buttons()
    show_start_information()

  ########################################################
  # COMMON FUNCTIONS
  ########################################################

  #-------------------------------------------------------
  # Show the Start page
  #-------------------------------------------------------
  show_start_information = ()->
    $("#start-info").removeClass "hidden"