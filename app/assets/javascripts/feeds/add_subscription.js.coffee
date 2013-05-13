#= require ./alert_hiding

$(document).ready ->

  #-------------------------------------------------------
  # Submit the "add subscription" form when clicking on the "Add" button
  #-------------------------------------------------------
  $("#subscribe-submit").on "click", ->
    $("#form-subscription").submit()

  #-------------------------------------------------------
  # Submit the "add subscription" form via Ajax
  #-------------------------------------------------------
  $("#form-subscription").on "submit", ->

    # Function to handle result returned by the server
    subscription_result = (data, status, xhr) ->
      $("#loading").addClass "hidden"
      if xhr.status == 304
        Application.alertTimedShowHide $("#already-subscribed")
      else
        # Insert the new feed in the "all subscriptions" list
        $("#folder-all-all-feeds").after data
        # Open the "all subscriptions" folder if not already open
        $("#feeds-all").not(".in").prev("a").click()
        # Select the new feed
        $("#folder-all-all-feeds").next().find("a").click()

    # If the user has written something in the form, POST the value via ajax
    if $("#subscription_rss").val()
      form_url = $("#form-subscription").attr "action"
      post_data = $(this).serialize()
      # Show "loading" message
      $("#loading").removeClass "hidden"
      $("#feed-entries").empty().addClass "hidden"
      $("#feed-title a").text ""
      $("#feed-title").addClass "hidden"
      $("#start-info").addClass "hidden"
      $.post(form_url, post_data, subscription_result)
        .fail ->
          $("#loading").addClass "hidden"
          $("#start-page").click()
          Application.alertTimedShowHide $("#problem-subscribing")

    # Clean textfield and close modal
    $("#subscription_rss").val('')
    $("#subscribe-feed-popup").modal 'hide'

    # prevent default form submit
    return false