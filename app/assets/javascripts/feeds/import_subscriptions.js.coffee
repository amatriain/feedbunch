#= require ./alert_hiding
#= require ./shared_functions

$(document).ready ->

  ########################################################
  # EVENTS
  ########################################################

  #-------------------------------------------------------
  # Show "Import subscriptions" popup when clicking on the import link
  #-------------------------------------------------------
  $("body").on "click", "a[data-import-subscriptions]", ->
    show_popup()

  ########################################################
  # COMMON FUNCTIONS
  ########################################################

  #-------------------------------------------------------
  # Show modal popup
  #-------------------------------------------------------
  show_popup = ->
    $("#import-subscriptions-popup").modal "show"