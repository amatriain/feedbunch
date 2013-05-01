$(document).ready ->

##########################################################
# DYNAMIC STYLES
##########################################################

  #-------------------------------------------------------
  # Dynamic styling when clicking on the sidebar folders
  #-------------------------------------------------------
  $(".menu-level1").click ->
    $(this).children("i.arrow").toggleClass "icon-chevron-right"
    $(this).children("i.arrow").toggleClass "icon-chevron-down"
    $(this).children("i.folder").toggleClass "icon-folder-close-alt"
    $(this).children("i.folder").toggleClass "icon-folder-open-alt"

  #-------------------------------------------------------
  # Dynamic styling when clicking on a feed in the sidebar
  #-------------------------------------------------------
  $("[data-feed-path]").click ->
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
  $("button[data-hide]").click ->
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

##########################################################
# AJAX
##########################################################

  #-------------------------------------------------------
  # Load new feed entries when clicking on the Refresh button
  #-------------------------------------------------------
  $("#refresh-feed").click ->
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
          $("#alert p").text "There has been a problem refreshing the feed. Please try again later"
          $("#alert").removeClass "hidden"

      $("#feed-entries").empty().load "#{feed_path}/refresh", null, insert_entries

  #-------------------------------------------------------
  # Load current feed entries when clicking on a feed in the sidebar
  #-------------------------------------------------------
  $("[data-feed-path]").click ->

    # Function to insert new entries in the list
    insert_entries = (entries, status, xhr) ->
      $(".icon-spin").removeClass("icon-spin").addClass "hidden"
      $("#loading").addClass "hidden"
      $("#refresh-feed").removeClass "disabled"
      if status in ["error", "timeout", "abort", "parsererror"]
        if xhr.status == 404
          showNoEntriesAlert()
        else
          $("#alert p").text "There has been a problem loading the feed. Please try again later"
          $("#alert").removeClass "hidden"

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
  $("#subscribe-submit").click ->
    $("#form-subscription").submit()

  #-------------------------------------------------------
  # Submit the "add subscription" form via Ajax
  #-------------------------------------------------------
  $("#form-subscription").on "submit", ->

    # Function to handle result returned by the server
    subscription_result = (data, status, xhr) ->
      $("#subscribe-feed-popup").modal 'hide'
      if xhr.status == 304
        $("#notice p").text "You are already subscribed to this feed"
        $("#notice").removeClass "hidden"

    # If the user has written something in the form, POST the value via ajax
    if $("#subscription_rss").val()
      form_url = $("#form-subscription").attr "action"
      post_data = $(this).serialize()
      $.post(form_url, post_data, subscription_result)
      .fail ->
        $("#subscribe-feed-popup").modal 'hide'
        $("#alert p").text "There has been a problem adding a subscription. Please try again later"
        $("#alert").removeClass "hidden"

      # Clean textfield
      $("#subscription_rss").val('')

    # If the form is blank, close the popup and do nothing else
    else
      $("#subscribe-feed-popup").modal 'hide'

    # prevent default form submit
    return false