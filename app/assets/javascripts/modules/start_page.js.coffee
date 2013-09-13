#= require ./alert_hiding
#= require ./shared_functions

$(document).ready ->

  ########################################################
  # EVENTS
  ########################################################

  #-------------------------------------------------------
  # Show the start page when clicking on the "Start" link
  #-------------------------------------------------------
  ###
  $("body").on "click", "#start-page", ->
    Feedbunch.hide_entries()
    Feedbunch.hide_feed_title()
    Feedbunch.hide_loading_message()
    Feedbunch.hide_buttons()
    show_start_information()
  ###

  ########################################################
  # COMMON FUNCTIONS
  ########################################################

  #-------------------------------------------------------
  # Show the Start page
  #-------------------------------------------------------
  show_start_information = ()->
    $("#start-info").removeClass "hidden"