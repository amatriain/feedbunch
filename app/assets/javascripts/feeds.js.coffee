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
  # Hide Rails notices with a timer
  #-------------------------------------------------------
  if $("#notice").length
    seconds = 5
    updateNoticeTimer = ->
      seconds -= 1
      $("#notice span[data-timer]").text seconds
      if seconds == 0
        clearInterval timerNotice
        $("#notice").alert "close"
    $("#notice span[data-timer]").text seconds
    timerNotice = setInterval updateNoticeTimer, 1000

  #-------------------------------------------------------
  # Hide Rails alerts with a timer
  #-------------------------------------------------------
  if $("#alert").length
    seconds = 5
    updateAlertTimer = ->
      seconds -= 1
      $("#alert span[data-timer]").text seconds
      if seconds == 0
        clearInterval timerAlert
        $("#alert").alert "close"
    $("#alert span[data-timer]").text seconds
    timerAlert = setInterval updateAlertTimer, 1000

  #-------------------------------------------------------
  # Hide Devise errors with a timer
  #-------------------------------------------------------
  if $("#devise-error").length
    seconds = 5
    updateDeviseTimer = ->
      seconds -= 1
      $("#devise-error span[data-timer]").text seconds
      if seconds == 0
        clearInterval timerDevise
        $("#devise-error").alert "close"
    $("#devise-error span[data-timer]").text seconds
    timerDevise = setInterval updateDeviseTimer, 1000

  #-------------------------------------------------------
  # Hide alerts when clicking the close button
  #-------------------------------------------------------
  $("button[data-hide]").on "click", ->
    $(this).parent().parent().addClass 'hidden'

  #-------------------------------------------------------
  # Show "no entries" alert, close it with a timer
  #-------------------------------------------------------
  showNoEntriesAlert = ->
    $("div#no-entries").removeClass "hidden"
    seconds = 5
    updateNoEntriesTimer = ->
      seconds -= 1
      $("#no-entries span[data-timer]").text seconds
      if seconds == 0
        clearInterval timerNoEntries
        $("#no-entries").addClass 'hidden'
    $("#no-entries span[data-timer]").text seconds
    timerNoEntries = setInterval updateNoEntriesTimer, 1000

  #-------------------------------------------------------
  # Show "problem refreshing" alert, close it with a timer
  #-------------------------------------------------------
  showProblemRefreshingAlert = ->
    $("div#problem-refreshing").removeClass "hidden"
    seconds = 5
    updateProblemRefreshingTimer = ->
      seconds -= 1
      $("#problem-refreshing span[data-timer]").text seconds
      if seconds == 0
        clearInterval timerProblemRefreshing
        $("#problem-refreshing").addClass 'hidden'
    $("#problem-refreshing span[data-timer]").text seconds
    timerProblemRefreshing = setInterval updateProblemRefreshingTimer, 1000

  #-------------------------------------------------------
  # Show "problem loading" alert, close it with a timer
  #-------------------------------------------------------
  showProblemLoadingAlert = ->
    $("div#problem-loading").removeClass "hidden"
    seconds = 5
    updateProblemLoadingTimer = ->
      seconds -= 1
      $("#problem-loading span[data-timer]").text seconds
      if seconds == 0
        clearInterval timerProblemLoading
        $("#problem-loading").addClass 'hidden'
    $("#problem-loading span[data-timer]").text seconds
    timerProblemLoading = setInterval updateProblemLoadingTimer, 1000

  #-------------------------------------------------------
  # Show "problem subscribing" alert, close it with a timer
  #-------------------------------------------------------
  showProblemSubscribingAlert = ->
    $("div#problem-subscribing").removeClass "hidden"
    seconds = 5
    updateProblemSubscribingTimer = ->
      seconds -= 1
      $("#problem-subscribing span[data-timer]").text seconds
      if seconds == 0
        clearInterval timerProblemSubscribing
        $("#problem-subscribing").addClass 'hidden'
    $("#problem-subscribing span[data-timer]").text seconds
    timerProblemSubscribing = setInterval updateProblemSubscribingTimer, 1000

  #-------------------------------------------------------
  # Show "already subscribed" alert, close it with a timer
  #-------------------------------------------------------
  showAlreadySubscribedAlert = ->
    $("div#already-subscribed").removeClass "hidden"
    seconds = 5
    updateAlreadySubscribedTimer = ->
      seconds -= 1
      $("#already-subscribed span[data-timer]").text seconds
      if seconds == 0
        clearInterval timerAlreadySubscribed
        $("#already-subscribed").addClass 'hidden'
    $("#already-subscribed span[data-timer]").text seconds
    timerAlreadySubscribed = setInterval updateAlreadySubscribedTimer, 1000

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
          showProblemRefreshingAlert()

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
          showNoEntriesAlert()
        else
          showProblemLoadingAlert()

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
      $("#subscribe-feed-popup").modal 'hide'
      if xhr.status == 304
        showAlreadySubscribedAlert()
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
      $.post(form_url, post_data, subscription_result)
      .fail ->
        $("#subscribe-feed-popup").modal 'hide'
        showProblemSubscribingAlert()

      # Clean textfield
      $("#subscription_rss").val('')

    # If the form is blank, close the popup and do nothing else
    else
      $("#subscribe-feed-popup").modal 'hide'

    # prevent default form submit
    return false