$(document).ready ->

  # Hide notice div when clicking on the "close" button.
  # The div is still there, just hidden, and so it can be manipulated and
  # made visible with javascript.
  $("#notice button").click ->
    $("#notice").addClass "hidden"

  # Hide alert div when clicking on the "close" button.
  # The div is still there, just hidden, and so it can be manipulated and
  # made visible with javascript.
  $("#alert button").click ->
    $("#alert").addClass "hidden"