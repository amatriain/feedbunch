$(document).ready ->

  #-------------------------------------------------------
  # Hide alerts when clicking the close button
  #-------------------------------------------------------
  $("body").on "click", "button[data-hide]", ->
    $(this).parent().parent().addClass 'hidden'
