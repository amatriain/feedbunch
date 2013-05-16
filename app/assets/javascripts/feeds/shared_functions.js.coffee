window.Application ||= {}

#-------------------------------------------------------
# Totally remove a folder from the sidebar and the dropdown
#-------------------------------------------------------
Application.remove_folder = (folder_id) ->
  $("#sidebar #folder-#{folder_id}").remove()
  $("#folder-management-dropdown a[data-folder-id='#{folder_id}']").parent().remove()