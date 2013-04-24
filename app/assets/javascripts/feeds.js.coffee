# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/

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
  $("[data-feed-id]").click ->
    $("[data-feed-id]").parent().removeClass "active"
    $(this).parent().addClass "active"

##########################################################
# AJAX
##########################################################

  #-------------------------------------------------------
  # Load new feed entries when clicking on the Refresh button
  #-------------------------------------------------------
  $("#refresh-feed").click ->
    feed_id = $(this).attr "data-refresh-feed"
    # Only refresh if the data-refresh-feed attribute has a reference to a feed id
    if feed_id?.length
      $("> i.icon-repeat", this).addClass "icon-spin"
      # Function to insert new entries in the list
      insert_entries = (entries, status, xhr) ->
        $("#refresh-feed > i.icon-repeat").removeClass "icon-spin"
        if status in ["error", "timeout", "abort", "parsererror"]
          $("#alert p").text "There has been a problem refreshing the feed. Please try again later"
          $("#alert").removeClass "hidden"
      $("#feed-entries").load "/feeds/#{feed_id}/refresh", null, insert_entries

  #-------------------------------------------------------
  # Load current feed entries when clicking on a feed in the sidebar
  #-------------------------------------------------------
  $("[data-feed-id]").click ->
    # Function to insert new entries in the list
    insert_entries = (entries, status, xhr) ->
      $(".icon-spin").removeClass("icon-spin").addClass "hidden"
      $("#loading").addClass "hidden"
      $("#refresh-feed").removeClass "disabled"
      if status in ["error", "timeout", "abort", "parsererror"]
        $("#alert p").text "There has been a problem loading the feed. Please try again later"
        $("#alert").removeClass "hidden"
    feed_id = $(this).attr "data-feed-id"
    # The refresh button now refreshes this feed
    $("#refresh-feed").attr "data-refresh-feed", feed_id
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
    $("#feed-entries").load "/feeds/#{feed_id}", null, insert_entries
