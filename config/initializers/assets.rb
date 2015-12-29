# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = '1.0'

# Add additional assets to the asset load path
# Rails.application.config.assets.paths << Emoji.images_path

# Add the images path to assets pipeline
Rails.application.config.assets.paths << Rails.root.join('vendor', 'assets', 'images')


#########################################
# Include NPM front-end modules in assets pipeline
#########################################

# Add the bower-components path to assets pipeline
Rails.application.config.assets.paths << Rails.root.join('vendor', 'assets', 'bower_components')

# Include Bootstrap-sass assets in assets paths
Rails.application.config.assets.paths << Rails.root.join('vendor', 'assets', 'bower_components', 'bootstrap-sass-official', 'assets', 'fonts')
Rails.application.config.assets.paths << Rails.root.join('vendor', 'assets', 'bower_components', 'bootstrap-sass-official', 'assets', 'javascripts')
Rails.application.config.assets.paths << Rails.root.join('vendor', 'assets', 'bower_components', 'bootstrap-sass-official', 'assets', 'stylesheets')

# Include enquire.js assets in assets paths
Rails.application.config.assets.paths << Rails.root.join('vendor', 'assets', 'bower_components', 'enquire', 'dist')

# Include favico.js assets in assets paths
Rails.application.config.assets.paths << Rails.root.join('vendor', 'assets', 'bower_components', 'favico.js')

# Include Fontawesome assets in assets paths
Rails.application.config.assets.paths << Rails.root.join('vendor', 'assets', 'bower_components', 'font-awesome', 'fonts')
Rails.application.config.assets.paths << Rails.root.join('vendor', 'assets', 'bower_components', 'font-awesome', 'scss')

# Include Hopscotch assets in assets paths
Rails.application.config.assets.paths << Rails.root.join('vendor', 'assets', 'bower_components', 'hopscotch', 'dist', 'css')
Rails.application.config.assets.paths << Rails.root.join('vendor', 'assets', 'bower_components', 'hopscotch', 'dist', 'img')
Rails.application.config.assets.paths << Rails.root.join('vendor', 'assets', 'bower_components', 'hopscotch', 'dist', 'js')

# Include is-in-viewport assets in assets paths
Rails.application.config.assets.paths << Rails.root.join('vendor', 'assets', 'bower_components', 'isInViewport', 'lib')

# Include JQuery assets in assets paths
Rails.application.config.assets.paths << Rails.root.join('vendor', 'assets', 'bower_components', 'jquery', 'dist')

# Include ng-infinite-scroll assets in assets paths
Rails.application.config.assets.paths << Rails.root.join('vendor', 'assets', 'bower_components', 'ngInfiniteScroll', 'build')

# Include urijs assets in assets paths
Rails.application.config.assets.paths << Rails.root.join('vendor', 'assets', 'bower_components', 'URIjs', 'src')

# Include velocity-animate assets in assets paths
Rails.application.config.assets.paths << Rails.root.join('vendor', 'assets', 'bower_components', 'velocity')

# Precompile additional assets.
# application.js, application.css, and all non-JS/CSS in app/assets folder are already added.
# Rails.application.config.assets.precompile += %w( search.js )
Rails.application.config.assets.precompile << /\.(?:svg|eot|woff|ttf|woff2|otf)\z/
Rails.application.config.assets.precompile += %w(*.png *.jpg *.jpeg *.gif)

# Precompile js libraries to serve them individually
Rails.application.config.assets.precompile += %w(
                                                  jquery.js
                                                  angular/angular.js
                                                  angular-sanitize/angular-sanitize.js
                                                  angular-touch/angular-touch.js
                                                  bootstrap-sass-official/assets/javascripts/bootstrap.js
                                                )