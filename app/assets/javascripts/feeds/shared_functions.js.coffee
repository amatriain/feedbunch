window.Openreader ||= {}

#-------------------------------------------------------
# Totally remove a folder from the sidebar and the dropdown
#-------------------------------------------------------
Openreader.remove_folder = (folder_id) ->
  $("#sidebar #folder-#{folder_id}").remove()
  $("#folder-management-dropdown a[data-folder-id='#{folder_id}']").parent().remove()

#-------------------------------------------------------
# Insert feed in a folder in the sidebar
#-------------------------------------------------------
Openreader.insert_feed_in_folder = (feed_id, folder_id, feed_data) ->
  $("#folder-#{folder_id}-all-feeds").after feed_data
  if folder_id=="all"
    Openreader.update_folder_id feed_id, "none"
  else
    Openreader.update_folder_id feed_id, folder_id

#-------------------------------------------------------
# Update the data-folder-id attribute for all links to a feed in the sidebar
#-------------------------------------------------------
Openreader.update_folder_id = (feed_id, folder_id) ->
  $("[data-sidebar-feed][data-feed-id='#{feed_id}']").attr "data-folder-id", folder_id

#-------------------------------------------------------
# Open a folder in the sidebar, if it's not already open
#-------------------------------------------------------
Openreader.open_folder = (folder_id) ->
  $("#sidebar #feeds-#{folder_id}").not(".in").prev("a").click()

#-------------------------------------------------------
# Read a feed under a specific folder
#-------------------------------------------------------
Openreader.read_feed = (feed_id, folder_id) ->
  Openreader.open_folder folder_id
  $("#feeds-#{folder_id} a[data-sidebar-feed][data-feed-id='#{feed_id}']").click()

#-------------------------------------------------------
# Hide the "Loading" message
#-------------------------------------------------------
Openreader.hide_loading_message = ->
  $("#loading").addClass "hidden"

#-------------------------------------------------------
# Show the "Loading" message
#-------------------------------------------------------
Openreader.show_loading_message = ->
  $("#loading").removeClass "hidden"