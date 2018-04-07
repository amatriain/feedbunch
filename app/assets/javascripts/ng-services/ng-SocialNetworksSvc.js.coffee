########################################################
# AngularJS service to share entries in social networks
########################################################

angular.module('feedbunch').service 'socialNetworksSvc',
['$rootScope', 'entrySvc',
($rootScope, entrySvc)->

  #---------------------------------------------
  # Share an entry on Google+
  #---------------------------------------------
  share_gplus_entry: (entry)->
    newWindow = window.open "https://plus.google.com/share?url=#{entry.url}",'', 'menubar=no,toolbar=no,resizable=yes,scrollbars=yes,height=600,width=600'
    newWindow.opener = null

  #---------------------------------------------
  # Share an entry on Linkedin
  #---------------------------------------------
  share_linkedin_entry: (entry)->
    # limit parameters to their maximum length, as indicated by linkedin docs:
    # https://developer.linkedin.com/documents/share-linkedin
    url = entry.url
    url = url.substring(0,1024) if url.length > 1024

    title = entry.title
    title = title.substring(0,200) if title.length > 200

    source = entrySvc.entry_feed_title entry
    source = source.substring(0,200) if source.length > 200

    if entry.summary?.length > 0
      # Strip html markup and send only plain text, otherwise the markup is escaped and visible in linkedin
      summary = entry.summary.replace /(<([^>]+)>)/ig, ''
      summary = summary.substring(0,256) if summary.length > 256
    else
      summary=''

    newWindow = window.open "http://www.linkedin.com/shareArticle?mini=true&url=#{url}&title=#{title}&summary=#{summary}&source=#{source}",'', 'menubar=no,toolbar=no,resizable=yes,scrollbars=yes,height=570,width=520'
    newWindow.opener = null
]