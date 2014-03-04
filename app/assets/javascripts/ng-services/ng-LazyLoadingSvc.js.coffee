########################################################
# AngularJS service to load lazily images in entries
########################################################

angular.module('feedbunch').service 'lazyLoadingSvc',
['$rootScope', ($rootScope)->

  #--------------------------------------------
  # PRIVATE FUNCTION: Lazy load a single image. Receives as argument the jQuery object wrapping the img.
  #--------------------------------------------
  load_image = (img)->
    img.on 'error', ->
      img.addClass 'hidden load-failed'
    .on 'load', ->
      if !img.hasClass 'load-failed'
        img.addClass('loaded').removeClass('hidden')
        # center and add display-block to images if wider than 30% of the entries div
        img_width = 100 * img.width() / $('#feed-entries').width()
        img.addClass 'center-block' if img_width > 40
    data_src = img.attr 'data-src'
    img.removeAttr('data-src').attr('src',  data_src)

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