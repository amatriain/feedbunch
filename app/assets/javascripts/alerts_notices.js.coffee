$(document).ready ->

  # Hide Rails notices with a timer
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

  # Hide Rails alerts with a timer
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

  # Hide Devise errors with a timer
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