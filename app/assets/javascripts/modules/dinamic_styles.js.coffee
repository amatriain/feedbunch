$(document).ready ->

  #-------------------------------------------------------
  # Dynamic styling when clicking on the sidebar folders
  #-------------------------------------------------------
  $("body").on "click", "[data-sidebar-folder]", ->
    # Toggle the down/right arrow and open/closed folder icons in this folder
    $(this).children("i.folder-arrow").toggleClass "icon-chevron-down"
    $(this).children("i.folder-arrow").toggleClass "icon-chevron-right"
    $(this).children("i.folder").toggleClass "icon-folder-open-alt"
    $(this).children("i.folder").toggleClass "icon-folder-close-alt"

    # Use the closed folder and right arrow on the rest of folders
    $("[data-sidebar-folder]").not(this).children("i.folder-arrow").removeClass "icon-chevron-down"
    $("[data-sidebar-folder]").not(this).children("i.folder-arrow").addClass "icon-chevron-right"
    $("[data-sidebar-folder]").not(this).children("i.folder").removeClass "icon-folder-open-alt"
    $("[data-sidebar-folder]").not(this).children("i.folder").addClass "icon-folder-close-alt"

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
  $("body").on "shown.bs.modal", "#subscribe-feed-popup",  ->
    $("#subscription_rss", this).focus()

  #-------------------------------------------------------
  # Give focus to the text input field when showing the "New folder" modal.
  #-------------------------------------------------------
  $("body").on "shown.bs.modal", "#new-folder-popup",  ->
    $("#new_folder_title", this).focus()

  #-------------------------------------------------------
  # Give focus to the cancel button when showing the "Unsubscribe" modal.
  #-------------------------------------------------------
  $("body").on "shown.bs.modal", "#unsubscribe-feed-popup",  ->
    $("#unsubscribe-cancel", this).focus()

  #-------------------------------------------------------
  # Give focus to the cancel button field when showing the "Import subscriptions" modal.
  #-------------------------------------------------------
  $("body").on "shown.bs.modal", "#data-import-popup",  ->
    $("#data-import-cancel", this).focus()