# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = '1.0'

# Add additional assets to the asset load path
# Rails.application.config.assets.paths << Emoji.images_path

# Add the images path to assets pipeline
Rails.application.config.assets.paths << Rails.root.join('vendor', 'assets', 'images')

# Add the bower-components path to assets pipeline
Rails.application.config.assets.paths << Rails.root.join('vendor', 'assets', 'bower_components')
# Necessary for bootstrap fonts
Rails.application.config.assets.paths << Rails.root.join("vendor","assets","bower_components","bootstrap-sass-official","assets","fonts")
# Necessary for fontawesome fonts
Rails.application.config.assets.paths << Rails.root.join("vendor","assets","bower_components","font-awesome", "fonts")

# Precompile additional assets.
# application.js, application.css, and all non-JS/CSS in app/assets folder are already added.
# Rails.application.config.assets.precompile += %w( search.js )
Rails.application.config.assets.precompile << /\.(?:svg|eot|woff|ttf|woff2|otf)\z/
Rails.application.config.assets.precompile += %w(*.png *.jpg *.jpeg *.gif)