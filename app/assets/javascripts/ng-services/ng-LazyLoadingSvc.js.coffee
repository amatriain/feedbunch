########################################################
# AngularJS service to load lazily images in entries
########################################################

angular.module('feedbunch').service 'lazyLoadingSvc',
['$rootScope', ($rootScope)->

  #--------------------------------------------
  # PRIVATE FUNCTION: Lazy load a single image. Receives as argument the jQuery object wrapping the img.
  #--------------------------------------------
  load_image = (img)->
    data_src = img.attr 'data-src'
    img.removeAttr 'data-src'
    img.attr 'src',  data_src

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