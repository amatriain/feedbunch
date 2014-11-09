##
# Rake task to clear the Rails cache.
# Look at the environment config files to see which cache backend is being used (file, memory, Redis...)

namespace :rails_cache do
  desc 'Clears the Rails cache'
  task :clear => :environment do
    Rails.cache.clear
  end
end