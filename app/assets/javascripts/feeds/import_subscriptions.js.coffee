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

    # If the user has not selected a file to upload, close the popup and to not POST
    # Form submit will be a full browser POST, because POSTing files via Ajax is not
    # widely supported in older browsers.
    if $("#import_subscriptions_file").val() == ''
      close_popup()
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