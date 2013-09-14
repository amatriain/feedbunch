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

  ########################################################
  # COMMON FUNCTIONS
  ########################################################

  #-------------------------------------------------------
  # Show modal popup
  #-------------------------------------------------------
  show_popup = ->
    $("#unsubscribe-feed-popup").modal "show" if $(this).hasClass("disabled")==false