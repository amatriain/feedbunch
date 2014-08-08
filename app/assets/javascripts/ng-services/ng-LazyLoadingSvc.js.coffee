########################################################
# AngularJS service to load lazily images in entries
########################################################

angular.module('feedbunch').service 'lazyLoadingSvc',
['$rootScope', 'animationsSvc', ($rootScope, animationsSvc)->

  #--------------------------------------------
  # PRIVATE FUNCTION: Lazy load a single image. Receives as argument the jQuery object wrapping the img.
  #--------------------------------------------
  load_image = (img)->
    # Create a clone of the image, hide it and load the actual image there. If it loads successfully,
    # hide the placeholder image and show the loaded image, otherwise hide both images.
    data_src = img.attr 'data-src'

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
      loaded_img.attr('src', data_src)

  service =

    #---------------------------------------------
    # Load images in the passed entry.
    #---------------------------------------------
    load_entry_images: (entry)->
      $("#entry-#{entry.id} .entry-content img[data-src]").each ->
        load_image $(this)

    #---------------------------------------------
    # Load images visible within the viewport (and 600px below it).
    #---------------------------------------------
    load_viewport_images: ->
      $('.entry .entry-content img[data-src]').withinViewportBottom({bottom: -600}).each ->
        load_image $(this)

  return service
]