# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = '1.0'

# Add additional assets to the asset load path
# Rails.application.config.assets.paths << Emoji.images_path

# Add the images path to assets pipeline
Rails.application.config.assets.paths << Rails.root.join('vendor', 'assets', 'images')

# Add the images path to assets pipeline
Rails.application.config.assets.paths << Rails.root.join('vendor', 'assets', 'bower-components')
# Necessary for bootstrap fonts
Rails.application.config.assets.paths << Rails.root.join("vendor","assets","bower_components","bootstrap-sass-official","assets","fonts")

# Precompile additional assets.
# application.js, application.css, and all non-JS/CSS in app/assets folder are already added.
# Rails.application.config.assets.precompile += %w( search.js )
Rails.application.config.assets.precompile += %w(.otf .eot .svg .ttf .woff)
Rails.application.config.assets.precompile += %w(*.png *.jpg *.jpeg *.gif)
# Necessary for bootstrap fonts
Rails.application.config.assets.precompile += %w( bootstrap/glyphicons-halflings-regular.eot
                                                  bootstrap/glyphicons-halflings-regular.woff2
                                                  bootstrap/glyphicons-halflings-regular.woff
                                                  bootstrap/glyphicons-halflings-regular.ttf )