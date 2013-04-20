# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/

$(document).ready ->

  # Dynamic styling when clicking on the sidebar folders
  $(".menu-level1").click ->
    $(this).children("i.arrow").toggleClass "icon-chevron-right"
    $(this).children("i.arrow").toggleClass "icon-chevron-down"
    $(this).children("i.folder").toggleClass "icon-folder-close-alt"
    $(this).children("i.folder").toggleClass "icon-folder-open-alt"

  # Dynamid styling when clicking on a feed in the sidebar
  $("[data-feed]").click ->
    $("[data-feed]").parent().removeClass "active"
    $(this).parent().addClass "active"

  # Load new feed entries when clicking on the Refresh button
  $("[data-refresh]").click ->
    # Function to insert new entries in the list
    insert_entries = (entries) ->
      $("#feed-entries").children(":first").before entries
    $.get "/feeds/1", null, insert_entries
