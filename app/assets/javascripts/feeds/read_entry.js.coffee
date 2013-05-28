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
      update_entry_state_result = (data, status, xhr) ->
        Openreader.update_folder_entry_count "all", data["folder_all"]["sidebar_read_all"]
        Openreader.update_feed_entry_count data["feed"]["id"], data["feed"]["sidebar"], true, Openreader.current_folder_id
        if data["folder"]
          Openreader.update_folder_entry_count data["folder"]["id"], data["folder"]["sidebar_read_all"]

      mark_entry_as_read entry_id
      $.post(update_entry_state_path, {_method:"put", id: entry_id, state: "read"},
              update_entry_state_result, "json")
        .fail (jqXHR, textStatus, errorThrown)->
          Openreader.alertTimedShowHide $("#problem-entry-state-change")


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