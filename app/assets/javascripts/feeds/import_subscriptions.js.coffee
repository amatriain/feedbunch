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

  #-------------------------------------------------------
  # Submit the "import subscriptions" form when clicking on the "Upload" button
  #-------------------------------------------------------
  $("body").on "click", "#import-subscriptions-submit", ->
    $("#form-import-subscriptions").submit()

  #-------------------------------------------------------
  # Submit the "import subscriptions" form via Ajax
  #-------------------------------------------------------
  $("body").on "submit", "#form-import-subscriptions", ->
    close_popup()

    # If the user has selected a file to upload, POST it via ajax
    if $("#import_subscriptions_file").val()
      alert "YESS"
    else
      alert "NOOO"

    # prevent default form submit
    return false

  ########################################################
  # COMMON FUNCTIONS
  ########################################################

  #-------------------------------------------------------
  # Show modal popup
  #-------------------------------------------------------
  show_popup = ->
    $("#import-subscriptions-popup").modal "show"

  #-------------------------------------------------------
  # Clean file field and close modal popup
  #-------------------------------------------------------
  close_popup = ->
    $("#import_subscriptions_file").val('')
    $("#import-subscriptions-popup").modal 'hide'