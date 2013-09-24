$(document).ready ->

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