$(document).ready ->

##########################################################
# DYNAMIC STYLES
##########################################################

  #-------------------------------------------------------
  # Dynamic styling when clicking on the sidebar folders
  #-------------------------------------------------------
  $(".menu-level1").on "click", ->
    $(this).children("i.arrow").toggleClass "icon-chevron-right"
    $(this).children("i.arrow").toggleClass "icon-chevron-down"
    $(this).children("i.folder").toggleClass "icon-folder-close-alt"
    $(this).children("i.folder").toggleClass "icon-folder-open-alt"

  #-------------------------------------------------------
  # Dynamic styling when clicking on a feed in the sidebar
  #-------------------------------------------------------
  $("body").on "click", "[data-feed-path]", ->
    $("[data-feed-path]").parent().removeClass "active"
    $(this).parent().addClass "active"

  #-------------------------------------------------------
  # Give focus to the text input field when showing the "Add subscription" modal.
  #-------------------------------------------------------
  $("#subscribe-feed-popup").on 'shown',  ->
    $("#subscription_rss", this).focus()

##########################################################
# ALERTS
##########################################################

  #-------------------------------------------------------
  # Hide alerts when clicking the close button
  #-------------------------------------------------------
  $("button[data-hide]").on "click", ->
    $(this).parent().parent().addClass 'hidden'

  #-------------------------------------------------------
  # Close the alert div passed as argument after 5 seconds.
  # Only works for Rails and Devise alerts.
  #-------------------------------------------------------
  alertTimedClose = (alert_div) ->
    seconds = 5
    updateTimer = ->
      seconds -= 1
      $("span[data-timer]", alert_div).text seconds
      if seconds == 0
        clearInterval timerAlert
        alert_div.alert "close"
    $("span[data-timer]", alert_div).text seconds
    timerAlert = setInterval updateTimer, 1000

  #-------------------------------------------------------
  # Show the alert div passed as argument and hide it after 5 seconds.
  # Only works for alerts caused by AJAX events.
  #-------------------------------------------------------
  alertTimedShowHide = (alert_div) ->
    alert_div.removeClass "hidden"
    seconds = 5
    updateTimer = ->
      # If the countdown has an unexpected value, another timer is running. Clear this one.
      if $("span[data-timer]", alert_div).text() != seconds.toString()
        clearInterval timerAlert
      else
        seconds -= 1
        $("span[data-timer]", alert_div).text seconds
        if seconds == 0
          clearInterval timerAlert
          alert_div.addClass "hidden"
    $("span[data-timer]", alert_div).text seconds
    timerAlert = setInterval updateTimer, 1000

  #-------------------------------------------------------
  # Hide Rails notices with a timer
  #-------------------------------------------------------
  if $("#notice").length
    alertTimedClose $("#notice")

  #-------------------------------------------------------
  # Hide Rails alerts with a timer
  #-------------------------------------------------------
  if $("#alert").length
    alertTimedClose $("#alert")

  #-------------------------------------------------------
  # Hide Devise errors with a timer
  #-------------------------------------------------------
  if $("#devise-error").length
    alertTimedClose $("#devise-error")

##########################################################
# AJAX
##########################################################

  #-------------------------------------------------------
  # Load new feed entries when clicking on the Refresh button
  #-------------------------------------------------------
  $("#refresh-feed").on "click", ->
    feed_path = $(this).attr "data-refresh-feed"
    # Only refresh if the data-refresh-feed attribute has a reference to a feed id
    if feed_path?.length
      $("> i.icon-repeat", this).addClass "icon-spin"
      # Show "loading" message
      $("#loading").removeClass "hidden"

      # Function to insert new entries in the list
      insert_entries = (entries, status, xhr) ->
        $("#refresh-feed > i.icon-repeat").removeClass "icon-spin"
        $("#loading").addClass "hidden"
        if status in ["error", "timeout", "abort", "parsererror"]
          alertTimedShowHide $("#problem-refreshing")

      $("#feed-entries").empty().load "#{feed_path}/refresh", null, insert_entries

  #-------------------------------------------------------
  # Load current feed entries when clicking on a feed in the sidebar
  #-------------------------------------------------------
  $("body").on "click", "[data-feed-path]", ->

    # Function to insert new entries in the list
    insert_entries = (entries, status, xhr) ->
      $(".icon-spin").removeClass("icon-spin").addClass "hidden"
      $("#loading").addClass "hidden"
      $("#refresh-feed").removeClass "disabled"
      if status in ["error", "timeout", "abort", "parsererror"]
        if xhr.status == 404
          alertTimedShowHide $("#no-entries")
        else
          alertTimedShowHide $("#problem-loading")

    # The refresh button now refreshes this feed
    feed_path = $(this).attr "data-feed-path"
    $("#refresh-feed").attr "data-refresh-feed", feed_path

    # Show the feed title
    feed_title = $(this).attr "data-feed-title"
    $("#feed-title a").text feed_title
    $("#feed-title").removeClass "hidden"

    # The feed title links to the feed url
    feed_url = $(this).attr "data-feed-url"
    $("#feed-title a").attr("href", feed_url)

    # Empty the entries list before loading
    $("#feed-entries > li").empty()

    # Show "loading" message
    $("#loading").removeClass "hidden"

    # Show a spinning icon while loading
    $(".icon-spinner", this).addClass("icon-spin").removeClass "hidden"

    # Load the entries via Ajax

    $("#feed-entries").load "#{feed_path}", null, insert_entries

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
        alertTimedShowHide $("#already-subscribed")
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
      $("#feed-entries").empty()
      $("#feed-title").addClass "hidden"
      $.post(form_url, post_data, subscription_result)
      .fail ->
        $("#loading").addClass "hidden"
        alertTimedShowHide $("#problem-subscribing")

    # Clean textfield and close modal
    $("#subscription_rss").val('')
    $("#subscribe-feed-popup").modal 'hide'

    # prevent default form submit
    return false