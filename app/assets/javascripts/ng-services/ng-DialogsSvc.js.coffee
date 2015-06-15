########################################################
# AngularJS service to give focus to certain form inputs as soon as the form is shown.
########################################################

angular.module('feedbunch').service 'dialogsSvc',
['$rootScope', 'keyboardShortcutsSvc'
($rootScope, keyboardShortcutsSvc)->

  #---------------------------------------------
  # Start responding to keyboard shortcuts
  #---------------------------------------------
  start: ->

    #-------------------------------------------------------
    # Hide the semitraslucent backdrop when a modal dialog is closed.
    # This is normally done automatically by Bootstrap but can fail in some cases leaving the backdrop permanently
    # visible, see:
    #   http://competa.com/blog/2013/11/how-to-stop-twitter-bootstrap-modal-dialogs-breaking-on-browser-history-navigation-in-angularjs/
    # The fix is to force the backdrop to be removed every time a modal is hidden.
    #-------------------------------------------------------
    $("body").on "hidden.bs.modal", ".modal",  ->
      # Remove the backdrop
      $('.modal-backdrop').remove()

    #-------------------------------------------------------
    # Give focus to the text input field when showing the "Add subscription" modal.
    #-------------------------------------------------------
    $("body").on "shown.bs.modal", "#subscribe-feed-popup",  ->
      # Stop responding to keyboard shortcuts
      keyboardShortcutsSvc.stop()
      $("#subscription_rss", this).focus()

    #-------------------------------------------------------
    # Reenable keyboard shortcuts when the "Add subscription" modal is hidden
    #-------------------------------------------------------
    $("body").on "hidden.bs.modal", "#subscribe-feed-popup",  ->
      # Start responding to keyboard shortcuts
      keyboardShortcutsSvc.start()

    #-------------------------------------------------------
    # Give focus to the text input field when showing the "New folder" modal.
    #-------------------------------------------------------
    $("body").on "shown.bs.modal", "#new-folder-popup",  ->
      # Stop responding to keyboard shortcuts
      keyboardShortcutsSvc.stop()
      $("#new_folder_title", this).focus()

    #-------------------------------------------------------
    # Reenable keyboard shortcuts when the "New folder" modal is hidden
    #-------------------------------------------------------
    $("body").on "hidden.bs.modal", "#new-folder-popup",  ->
      # Start responding to keyboard shortcuts
      keyboardShortcutsSvc.start()

    #-------------------------------------------------------
    # Give focus to the cancel button when showing the "Unsubscribe" modal.
    #-------------------------------------------------------
    $("body").on "shown.bs.modal", "#unsubscribe-feed-popup",  ->
      # Stop responding to keyboard shortcuts
      keyboardShortcutsSvc.stop()
      $("#unsubscribe-cancel", this).focus()

    #-------------------------------------------------------
    # Reenable keyboard shortcuts when the "Unsubscribe" modal is hidden
    #-------------------------------------------------------
    $("body").on "hidden.bs.modal", "#unsubscribe-feed-popup",  ->
      # Start responding to keyboard shortcuts
      keyboardShortcutsSvc.start()

    #-------------------------------------------------------
    # Give focus to the close button when showing the "Keyboard shortcuts" modal.
    #-------------------------------------------------------
    $("body").on "shown.bs.modal", "#help-kb-shortcuts-popup",  ->
      # Stop responding to keyboard shortcuts
      keyboardShortcutsSvc.stop()
      $("#kb-shortcuts-close", this).focus()

    #-------------------------------------------------------
    # Reenable keyboard shortcuts when the "Keyboard shortcuts" modal is hidden
    #-------------------------------------------------------
    $("body").on "hidden.bs.modal", "#help-kb-shortcuts-popup",  ->
      # Start responding to keyboard shortcuts
      keyboardShortcutsSvc.start()

    #-------------------------------------------------------
    # Give focus to the close button when showing the "Help and Feedback" modal.
    #-------------------------------------------------------
    $("body").on "shown.bs.modal", "#help-feedback-popup",  ->
      # Stop responding to keyboard shortcuts
      keyboardShortcutsSvc.stop()
      $("#help-close", this).focus()

    #-------------------------------------------------------
    # Reenable keyboard shortcuts when the "Help and Feedback" modal is hidden
    #-------------------------------------------------------
    $("body").on "hidden.bs.modal", "#help-feedback-popup",  ->
      # Start responding to keyboard shortcuts
      keyboardShortcutsSvc.start()

    #-------------------------------------------------------
    # Give focus to the cancel button when showing the "Import subscriptions" modal.
    #-------------------------------------------------------
    $("body").on "shown.bs.modal", "#opml-import-popup",  ->
      # Stop responding to keyboard shortcuts
      keyboardShortcutsSvc.stop()
      $("#opml-import-cancel", this).focus()

    #-------------------------------------------------------
    # Reenable keyboard shortcuts when the "Import subscriptions" modal is hidden
    #-------------------------------------------------------
    $("body").on "hidden.bs.modal", "#opml-import-popup",  ->
      # Start responding to keyboard shortcuts
      keyboardShortcutsSvc.start()

    #-------------------------------------------------------
    # Give focus to the cancel button when showing the "Delete account" modal.
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

]