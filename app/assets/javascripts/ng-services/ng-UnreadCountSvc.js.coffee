########################################################
# AngularJS service to manage unread entries counts
########################################################

angular.module('feedbunch').service 'unreadCountSvc',
['currentFeedSvc', 'findSvc',
(currentFeedSvc, findSvc)->

  #--------------------------------------------
  # Increment or decrement the count of unread entries in feeds corresponding to the passed entries.
  # Receives as argument an array of entries and a boolean indicating whether to
  # increment (true) or decrement (false) the count.
  #--------------------------------------------
  update_unread_count: (entries, increment)->
    if currentFeedSvc.get()
      # if current_feed has value, all entries belong to the same feed which simplifies things
      if increment
        currentFeedSvc.get().unread_entries += entries.length
      else
        currentFeedSvc.get().unread_entries -= entries.length
    else
      # if current_feed has null value, each entry can belong to a different feed
      # we process each entry individually
      for entry in entries
        feed = findSvc.find_feed entry.feed_id
        if increment
          feed.unread_entries += 1
        else
          feed.unread_entries -= 1
]