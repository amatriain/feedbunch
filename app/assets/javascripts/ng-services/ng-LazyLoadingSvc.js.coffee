########################################################
# AngularJS service to load lazily images in entries
########################################################

angular.module('feedbunch').service 'lazyLoadingSvc',
['$rootScope', 'animationsSvc', 'findSvc',
($rootScope, animationsSvc, findSvc)->

  #--------------------------------------------
  # PRIVATE FUNCTION: Lazy load a single image. Receives as arguments:
  # - jQuery object wrapping the img.
  # - entry to which the image belongs
  #--------------------------------------------
  load_image = (img, entry=null)->
    # Create a clone of the image, hide it and load the actual image there. If it loads successfully,
    # hide the placeholder image and show the loaded image, otherwise hide both images.
    data_src = img.attr 'data-src'
    uri = new URI(data_src).normalize()

    # Convert relative URIs to absolute, using the feed hostname
    if uri.is('relative') && entry?
      feed = findSvc.find_feed entry.feed_id
      feed_uri = new URI(feed.url).normalize()
      uri.host feed_uri.host()

    if !data_src || data_src?.trim()?.length == 0
      # If data-src is blank, just hide the spinner
      img.addClass 'hidden'
    else
      # If data-src is not blank, lazy-load the image
      img.removeAttr('data-src')
      loaded_img = img.clone().addClass('loading').removeAttr('src').insertAfter(img)
      loaded_img.on 'error', ->
        img.addClass 'hidden'
      .on 'load', ->
        img.addClass 'hidden'
        animationsSvc.show_image loaded_img
      loaded_img.attr 'src', uri.toString()

  service =

    #---------------------------------------------
    # Load images in the passed entry.
    #---------------------------------------------
    load_entry_images: (entry)->
      $("#entry-#{entry.id} .entry-content img[data-src]").each ->
        load_image $(this), entry

    #---------------------------------------------
    # Load images visible within the viewport (and 600px below it).
    #---------------------------------------------
    load_viewport_images: ->
      $('.entry .entry-content img[data-src]').withinViewportBottom({bottom: -600}).each ->
        load_image $(this)

  return service
]