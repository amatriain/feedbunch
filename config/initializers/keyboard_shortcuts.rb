# Default keyboard shortcuts
Rails.application.configure do

  # select sidebar link (feed, folder, start) for reading
  config.kb_select_sidebar_link = 13 #enter

  # toggle open/close state of currently highlighted entry
  config.kb_toggle_open_entry = 32 #spacebar

  # move up the sidebar
  config.kb_sidebar_link_up = 104 # h

  # move down the sidebar
  config.kb_sidebar_link_down = 108 # l

  # move up the entries list
  config.kb_entries_up = 107 # k

  # move down the entries list
  config.kb_entries_down = 106 # j

  # toggle show/hide read entries
  config.kb_toggle_show_read = 100 # d

  # mark all entries as read
  config.kb_mark_all_read = 97 # a

  # toggle read/unread state of currently highlighted entry
  config.kb_toggle_read_entry = 114 # r
end