########################################################
# Give focus to certain form inputs as soon as the form is shown.
########################################################

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
  # Give focus to the close button when showing the "Help and Feedback" modal.
  #-------------------------------------------------------

  $("body").on "shown.bs.modal", "#help-feedback-popup",  ->
    $("#help-close", this).focus()

  #-------------------------------------------------------
  # Give focus to the cancel button when showing the "Import subscriptions" modal.
  #-------------------------------------------------------

  $("body").on "shown.bs.modal", "#opml-import-popup",  ->
    $("#opml-import-cancel", this).focus()

  #-------------------------------------------------------
  # Give focus to the cancel button when showing the "Unsubscribe" modal.
  #-------------------------------------------------------
  $("body").on "shown.bs.modal", "#profile-delete-popup",  ->
    $("#profile-delete-cancel", this).focus()

  #-------------------------------------------------------
  # Give focus to the email field when showing the "Send invitation" modal.
  #-------------------------------------------------------
  $("body").on "shown.bs.modal", "#invite-friend-popup",  ->
    $("#user_invitation_email", this).focus()

  #-------------------------------------------------------
  # Give focus to the close button when showing the "Demo user info" modal.
  #-------------------------------------------------------
  $("body").on "shown.bs.modal", "#demo-info-popup",  ->
    $("#demo-info-close", this).focus()