#= require ./alert_hiding
#= require ./shared_functions

$(document).ready ->

  #-------------------------------------------------------
  # Submit the "add subscription" form when clicking on the "Add" button
  #-------------------------------------------------------
  $("body").on "click", "#subscribe-submit", ->
    $("#form-subscription").submit()

  #-------------------------------------------------------
  # Submit the "add subscription" form via Ajax
  #-------------------------------------------------------
  $("body").on "submit", "#form-subscription", ->

    # Function to handle result returned by the server
    subscription_result = (data, status, xhr) ->
      Openreader.hide_loading_message()
      if xhr.status == 304
        Openreader.alertTimedShowHide $("#already-subscribed")
      else
        Openreader.insert_feed_in_folder data["id"], "all", data["sidebar"]
        Openreader.read_feed data["id"], "all"

    # If the user has written something in the form, POST the value via ajax
    if $("#subscription_rss").val()
      form_url = $("#form-subscription").attr "action"
      post_data = $(this).serialize()
      # Show "loading" message
      Openreader.show_loading_message()
      $("#feed-entries").empty().addClass "hidden"
      $("#feed-title a").text ""
      $("#feed-title").addClass "hidden"
      $("#start-info").addClass "hidden"
      $.post(form_url, post_data, subscription_result, 'json')
        .fail ->
          $("#loading").addClass "hidden"
          $("#start-page").click()
          Openreader.alertTimedShowHide $("#problem-subscribing")

    # Clean textfield and close modal
    $("#subscription_rss").val('')
    $("#subscribe-feed-popup").modal 'hide'

    # prevent default form submit
    return false