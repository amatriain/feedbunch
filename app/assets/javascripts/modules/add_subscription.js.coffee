#= require ./alert_hiding
#= require ./shared_functions

$(document).ready ->

  ########################################################
  # EVENTS
  ########################################################

  #-------------------------------------------------------
  # Submit the "add subscription" form via Ajax
  #-------------------------------------------------------
  $("body").on "submit", "#form-subscription", ->

    # Function to handle result returned by the server
    subscription_result = (data, status, xhr) ->
      Feedbunch.hide_loading_message()
      if xhr.status == 304
        Feedbunch.alertTimedShowHide $("#already-subscribed")
        Feedbunch.show_start_page()
      else
        Feedbunch.insert_feed_in_folder data["id"], "all", data["sidebar_feed"]
        Feedbunch.update_folder_entry_count "all", data["sidebar_read_all"]
        Feedbunch.read_feed data["id"], "all"

    # If the user has written something in the form, POST the value via ajax
    if $("#subscription_rss").val()
      form_url = $("#form-subscription").attr "action"
      rss_url = $("#subscription_rss").val()
      Feedbunch.loading_entries()
      Feedbunch.hide_feed_title()
      $.post(form_url, feed: {url: rss_url}, subscription_result, 'json')
        .fail ->
          Feedbunch.hide_loading_message()
          Feedbunch.show_start_page()
          Feedbunch.alertTimedShowHide $("#problem-subscribing")

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
