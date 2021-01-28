# Whitelist of accepted tags and attributes when sanitizing entries, folder titles etc.
# This list is a more restrictive version of:
# https://github.com/flavorjones/loofah/blob/master/lib/loofah/html5/whitelist.rb
Rails.application.config.action_view.sanitized_allowed_attributes = %w[alt border cite colspan color coords datetime
      dir headers href hreflang ismap label lang loop loopcount loopend loopstart media poster preload
      rel rev rowspan scope shape span src start summary target title usemap]

Rails.application.config.action_view.sanitized_allowed_tags = %w[a abbr acronym address area
      article aside audio b bdi bdo big blockquote br canvas
      caption center cite code col colgroup dd del
      dfn div dl dt em figcaption figure footer
      h1 h2 h3 h4 h5 h6 header hr i img ins kbd
      li map mark nav ol p
      pre q s samp section small span strike strong sub
      sup table tbody td tfoot th thead time tr tt u ul var
      video]