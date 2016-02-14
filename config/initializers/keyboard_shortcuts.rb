# Default keyboard shortcuts
Rails.application.configure do

  # select sidebar link (feed, folder, start) for reading
  config.kb_select_sidebar_link = 13 #enter

  # toggle open/close state of currently highlighted entry
  config.kb_toggle_open_entry = 32 #spacebar

  # move up the sidebar
  config.kb_sidebar_link_up = 72 # h

  # move down the sidebar
  config.kb_sidebar_link_down = 76 # l

  # move up the entries list
  config.kb_entries_up = 75 # k

  # move down the entries list
  config.kb_entries_down = 74 # j

  # toggle show/hide read entries
  config.kb_toggle_show_read = 68 # d

  # mark all entries as read
  config.kb_mark_all_read = 65 # a

  # toggle read/unread state of currently highlighted entry
  config.kb_toggle_read_entry = 82 # r
end