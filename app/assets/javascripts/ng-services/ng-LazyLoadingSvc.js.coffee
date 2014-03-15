########################################################
# AngularJS service to load lazily images in entries
########################################################

angular.module('feedbunch').service 'lazyLoadingSvc',
['$rootScope', ($rootScope)->

  #--------------------------------------------
  # PRIVATE FUNCTION: Lazy load a single image. Receives as argument the jQuery object wrapping the img.
  #--------------------------------------------
  load_image = (img)->
    # Create a clone of the image, hide it and load the actual image there. If it loads successfully,
    # hide the placeholder image and show the loaded image, otherwise hide both images.
    data_src = img.attr 'data-src'
    img.removeAttr('data-src')
    loaded_img = img.clone().addClass('hidden').removeAttr('src').insertAfter(img)
    loaded_img.on 'error', ->
      img.addClass 'hidden'
    .on 'load', ->
      img.addClass 'hidden'
      loaded_img.addClass('loaded').removeClass('hidden')
      # center and add display-block to images if wider than 40% of the entries div
      img_width = 100 * loaded_img.width() / $('#feed-entries').width()
      loaded_img.addClass 'center-block' if img_width > 40
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