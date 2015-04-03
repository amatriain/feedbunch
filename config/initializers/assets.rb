# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = '1.0'

# Add additional assets to the asset load path
# Rails.application.config.assets.paths << Emoji.images_path

# Add the images path to assets pipeline
Rails.application.config.assets.paths << Rails.root.join('vendor', 'assets', 'images')

# Add the bower-components path to assets pipeline
Rails.application.config.assets.paths << Rails.root.join('vendor', 'assets', 'bower_components')
# Add fallback.js path to asset pipeline
Rails.application.config.assets.paths << Rails.root.join('vendor', 'assets', 'bower_components', 'fallback')

# Necessary for bootstrap fonts
Rails.application.config.assets.paths << Rails.root.join("vendor","assets","bower_components","bootstrap-sass-official","assets","fonts")
# Necessary for fontawesome fonts
Rails.application.config.assets.paths << Rails.root.join("vendor","assets","bower_components","font-awesome", "fonts")

# Precompile additional assets.
# application.js, application.css, and all non-JS/CSS in app/assets folder are already added.
# Rails.application.config.assets.precompile += %w( search.js )
Rails.application.config.assets.precompile << /\.(?:svg|eot|woff|ttf|woff2|otf)\z/
Rails.application.config.assets.precompile += %w(*.png *.jpg *.jpeg *.gif)

# Precompile js libraries to serve them individually as fallback if CDN goes down
Rails.application.config.assets.precompile += %w(
                                                  fallback.js
                                                  fallback_js/load_libraries.js
                                                  jquery/dist/jquery.js
                                                  angular/angular.js
                                                  angular-sanitize/angular-sanitize.js
                                                  angular-touch/angular-touch.js
                                                  bootstrap-sass-official/assets/javascripts/bootstrap.js
                                                )