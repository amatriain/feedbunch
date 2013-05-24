#= require ./alert_hiding
#= require ./shared_functions

$(document).ready ->

  ########################################################
  # EVENTS
  ########################################################

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
        Openreader.insert_feed_in_folder data["id"], "all", data["sidebar_feed"]
        Openreader.update_folder_entry_count "all", data["sidebar_read_all"]
        Openreader.read_feed data["id"], "all"

    # If the user has written something in the form, POST the value via ajax
    if $("#subscription_rss").val()
      form_url = $("#form-subscription").attr "action"
      post_data = $(this).serialize()
      Openreader.loading_entries()
      Openreader.hide_feed_title()
      $.post(form_url, post_data, subscription_result, 'json')
        .fail ->
          Openreader.hide_loading_message()
          Openreader.show_start_page()
          Openreader.alertTimedShowHide $("#problem-subscribing")

    close_popup()

    # prevent default form submit
    return false

  ########################################################
  # COMMON FUNCTIONS
  ########################################################

  #-------------------------------------------------------
  # Clean textfield and close modal popup
  #-------------------------------------------------------
  close_popup = ->
    $("#subscription_rss").val('')
    $("#subscribe-feed-popup").modal 'hide'
