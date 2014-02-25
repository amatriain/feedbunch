########################################################
# AngularJS service to load lazily images in entries
########################################################

angular.module('feedbunch').service 'lazyLoadingSvc',
['$rootScope', ($rootScope)->

  #---------------------------------------------
  # Load images in the passed entry.
  #---------------------------------------------
  load_entry_images: (entry)->
    $("#entry-#{entry.id} .entry-content img[data-src]").each ->
      data_src = $(this).attr 'data-src'
      $(this).removeAttr 'data-src'
      $(this).attr 'src',  data_src

  #---------------------------------------------
  # Load images visible within the viewport.
  #---------------------------------------------
  load_viewport_images: ->
    $('.entry .entry-content img[data-src]').each ->
      data_src = $(this).attr 'data-src'
      $(this).removeAttr 'data-src'
      $(this).attr 'src',  data_src
]