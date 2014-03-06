########################################################
# AngularJS service to manage unread entries counts
########################################################

angular.module('feedbunch').service 'changeUnreadCountSvc',
['findSvc', 'favicoSvc', (findSvc, favicoSvc)->

  #--------------------------------------------
  # Increment or decrement by 1 the count of unread entries in the feed corresponding to the passed entry.
  # Receives as argument an entry and a boolean indicating whether to
  # increment (true) or decrement (false) the count.
  #--------------------------------------------
  update_unread_count: (entry, increment)->
    feed = findSvc.find_feed entry.feed_id
    if feed
      if increment
        feed.unread_entries += 1
      else
        feed.unread_entries -= 1 if feed.unread_entries > 0
      favicoSvc.update_unread_badge()

  #--------------------------------------------
  # Set the unread entries count of a feed to zero
  #--------------------------------------------
  zero_feed_count: (feed_id)->
    feed = findSvc.find_feed feed_id
    if feed
      feed.unread_entries = 0
      favicoSvc.update_unread_badge()

  #--------------------------------------------
  # Set the unread entries count of a folder and its feeds to zero
  #--------------------------------------------
  zero_folder_count: (folder)->
    feeds = findSvc.find_folder_feeds folder
    if feeds && feeds?.length > 0
      for feed in feeds
        feed.unread_entries = 0
      favicoSvc.update_unread_badge()
]