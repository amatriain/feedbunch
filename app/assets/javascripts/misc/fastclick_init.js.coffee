########################################################
# Initialize the fastclick JS library to eliminate click delay in touchscreens.
########################################################

$( ->
  attachFastClick = Origami.fastclick
  attachFastClick document.body
)