$(document).ready ->

  #-------------------------------------------------------
  # Dynamic styling when clicking on the sidebar folders
  #-------------------------------------------------------
  $("body").on "click", "[data-sidebar-folder]", ->
    $(this).children("i.arrow").toggleClass "icon-chevron-right"
    $(this).children("i.arrow").toggleClass "icon-chevron-down"
    $(this).children("i.folder").toggleClass "icon-folder-close-alt"
    $(this).children("i.folder").toggleClass "icon-folder-open-alt"

  #-------------------------------------------------------
  # Dynamic styling when clicking on the "Start" link in the sidebar
  #-------------------------------------------------------
  $("body").on "click", "#start-page", ->
    $("[data-sidebar-feed]").parent().removeClass "active"
    $(this).parent().addClass "active"

  #-------------------------------------------------------
  # Dynamic styling when clicking on a feed in the sidebar
  #-------------------------------------------------------
  $("body").on "click", "[data-sidebar-feed]", ->
    $("#start-page").parent().removeClass "active"
    $("[data-sidebar-feed]").parent().removeClass "active"
    $(this).parent().addClass "active"

  #-------------------------------------------------------
  # Give focus to the text input field when showing the "Add subscription" modal.
  #-------------------------------------------------------
  $("body").on "shown", "#subscribe-feed-popup",  ->
    $("#subscription_rss", this).focus()

  #-------------------------------------------------------
  # Give focus to the text input field when showing the "New folder" modal.
  #-------------------------------------------------------
  $("body").on "shown", "#new-folder-popup",  ->
    $("#new_folder_title", this).focus()