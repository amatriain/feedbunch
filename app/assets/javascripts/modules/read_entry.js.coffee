#= require ./alert_hiding
#= require ./shared_functions

$(document).ready ->

  ########################################################
  # EVENTS
  ########################################################

  #-------------------------------------------------------
  # Mark entry as read as soon as the user opens it
  #-------------------------------------------------------
  $("body").on "show", "[data-entry-summary-id]", ->
    if opening_entry this
      update_entry_state_path = $(this).attr "data-entry-state-update-path"
      entry_id = $(this).attr "data-entry-summary-id"

      # Function to handle result returned by the server
      entry_read_result = (data, status, xhr) ->
        mark_entry_as_read entry_id
        update_unread_counts data

      $.post(update_entry_state_path,
        {_method:"put", entry_ids: [entry_id], state: "read"},
        entry_read_result, "json")
        .fail ->
          Feedbunch.alertTimedShowHide $("#problem-entry-state-change")

  #-------------------------------------------------------
  # Mark all visible entries as read when clicking on the "mark all as read" button
  #-------------------------------------------------------
  $("body").on "click", "#read-all-button", ->
    if $(this).hasClass("disabled") == false
      update_entry_state_path = $(this).attr "data-entry-state-update-path"
      entries = []
      $("[data-entry-id]").each ->
        entry_id = $(this).attr "data-entry-id"
        entries.push entry_id

      # Function to handle result returned by the server
      all_read_result = (data, status, xhr) ->
        for id in entries
          mark_entry_as_read id
        update_unread_counts data

      $.post(update_entry_state_path,
        {_method:"put", entry_ids: entries, state: "read"},
        all_read_result, "json")
          .fail ->
            Feedbunch.alertTimedShowHide $("#problem-entry-state-change")

  #-------------------------------------------------------
  # Mark a single entry as unread when clicking on the "mark as unread" button
  #-------------------------------------------------------
  $("body").on "click", "[data-unread-entry-id]", ->
    update_entry_state_path = $(this).attr "data-entry-state-update-path"
    entry_id = $(this).attr "data-unread-entry-id"

    # Function to handle result returned by the server
    entry_unread_result = (data, status, xhr) ->
      mark_entry_as_unread entry_id
      update_unread_counts data
      
    $.post(update_entry_state_path,
      {_method:"put", entry_ids: [entry_id], state: "unread"},
      entry_unread_result, "json")
          .fail ->
            Feedbunch.alertTimedShowHide $("#problem-entry-state-change")

  ########################################################
  # COMMON FUNCTIONS
  ########################################################

  #-------------------------------------------------------
  # Returns a boolean: true if user is opening the entry, false if he's closing it
  #-------------------------------------------------------
  opening_entry = (entry_link) ->
    entry_id = $(entry_link).attr "data-entry-id"
    summary = $(entry_link).next("[data-entry-summary-id='#{entry_id}']")
    return !summary.hasClass "in"

  #-------------------------------------------------------
  # Mark visually an entry as read by adding a CSS class to it
  #-------------------------------------------------------
  mark_entry_as_read = (entry_id) ->
    $("[data-entry-id='#{entry_id}']").removeClass("entry-unread").addClass "entry-read"

  #-------------------------------------------------------
  # Mark visually an entry as unread by adding a CSS class to it
  #-------------------------------------------------------
  mark_entry_as_unread = (entry_id) ->
    $("[data-entry-id='#{entry_id}']").removeClass("entry-read").addClass "entry-unread"

  #-------------------------------------------------------
  # Function to handle result returned by the server
  #-------------------------------------------------------
  update_unread_counts = (data) ->
    Feedbunch.update_folder_entry_count "all", data["folder_all"]["sidebar_read_all"]

    if data["feeds"]
      changed_feeds = data["feeds"]
      for feed in changed_feeds
        Feedbunch.update_feed_entry_count feed["id"], feed["sidebar"]

    if data["folders"]
      changed_folders = data["folders"]
      for folder in changed_folders
        Feedbunch.update_folder_entry_count folder["id"], folder["sidebar_read_all"]

    Feedbunch.make_active Feedbunch.current_feed_id, Feedbunch.current_folder_id