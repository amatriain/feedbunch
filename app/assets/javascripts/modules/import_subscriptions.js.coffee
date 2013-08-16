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
  $("body").on "click", "#data-import-submit", ->
    $("#form-data-import").submit()

  #-------------------------------------------------------
  # Close the popup when submitting the form
  #-------------------------------------------------------
  $("body").on "submit", "#form-data-import", ->

    # If the user has not selected a file to upload, close the popup and to not POST
    # Form submit will be a full browser POST, because POSTing files via Ajax is not
    # widely supported in older browsers.
    if $("#data_import_file").val() == ''
      close_popup()
      return false

  #-------------------------------------------------------
  # Periodically update the import process status while it is running
  #-------------------------------------------------------
  update_status_timer = ->

    update_import_status = ->
      # Update the page with the received status
      status_received = (data, textStatus, xhr) ->
        status = data["status"]
        if status == "NONE"
          update_status_html data["status_html"]
          clearInterval timer_update
        else if status == "SUCCESS"
          update_status_html data["status_html"]
          clearInterval timer_update
          Feedbunch.alertTimedShowHide $("#import-process-success")
        else if status == "ERROR"
          update_status_html data["status_html"]
          clearInterval timer_update
          Feedbunch.alertTimedShowHide $("#import-process-error")
        else if status == "RUNNING"
          update_status_html data["status_html"]

      # Load the status via Ajax
      $.get("/data_imports", null, status_received, 'json')
        .fail (xhr, textStatus, errorThrown) ->
          if xhr.status != 304
            Feedbunch.alertTimedShowHide $("#problem-updating-import-status")

    timer_update = setInterval update_import_status, 5000

  #-------------------------------------------------------
  # If the "import running" div is shown, periodically update import status
  #-------------------------------------------------------

  if $("#data-import-running").length
    update_status_timer()

  ########################################################
  # COMMON FUNCTIONS
  ########################################################

  #-------------------------------------------------------
  # Show modal popup
  #-------------------------------------------------------
  show_popup = ->
    $("#data-import-popup").modal "show"

  #-------------------------------------------------------
  # Clean file field and close modal popup
  #-------------------------------------------------------
  close_popup = ->
    $("#data_import_file").val('')
    $("#data-import-popup").modal 'hide'

  #-------------------------------------------------------
  # Load the import status div sent by the server, replacing the current one
  #-------------------------------------------------------
  update_status_html = (status_html)->
    $("#import-process-status").html status_html