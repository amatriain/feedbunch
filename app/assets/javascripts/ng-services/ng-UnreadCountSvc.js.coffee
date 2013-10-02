########################################################
# AngularJS service to manage unread entries counts
########################################################

angular.module('feedbunch').service 'unreadCountSvc',
['currentFeedSvc', 'findSvc',
(currentFeedSvc, findSvc)->

  #--------------------------------------------
  # Increment or decrement by 1 the count of unread entries in the feed corresponding to the passed entry.
  # Receives as argument an entry and a boolean indicating whether to
  # increment (true) or decrement (false) the count.
  #--------------------------------------------
  update_unread_count: (entry, increment)->
    feed = findSvc.find_feed entry.feed_id
    if increment
      feed.unread_entries += 1
    else
      feed.unread_entries -= 1

  #--------------------------------------------
  # Set the unread entries count of a feed to zero
  #--------------------------------------------
  zero_unread_count: (feed)->
    feed.unread_entries = 0
]