window.Feedbunch ||= {}

$(document).ready ->

  #-------------------------------------------------------
  # Hide alerts when clicking the close button
  #-------------------------------------------------------
  $("body").on "click", "button[data-hide]", ->
    $(this).parent().parent().addClass 'hidden'

  #-------------------------------------------------------
  # Show the alert div passed as argument and hide it after 5 seconds.
  # Only works for alerts caused by AJAX events.
  #-------------------------------------------------------
  Feedbunch.alertTimedShowHide = (alert_div) ->
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
  # Hide Rails notices with a timer
  #-------------------------------------------------------
  if $("#notice").length
    alertTimedClose $("#notice")

  #-------------------------------------------------------
  # Hide Rails alerts with a timer
  #-------------------------------------------------------
  if $("#alert").length
    alertTimedClose $("#alert")