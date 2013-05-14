$(document).ready ->

  #-------------------------------------------------------
  # Dynamic styling when clicking on the sidebar folders
  #-------------------------------------------------------
  $(".menu-level1").on "click", ->
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
  $("#subscribe-feed-popup").on 'shown',  ->
    $("#subscription_rss", this).focus()

  #-------------------------------------------------------
  # Give focus to the text input field when showing the "New folder" modal.
  #-------------------------------------------------------
  $("#new-folder-popup").on 'shown',  ->
    $("#new_folder_title", this).focus()