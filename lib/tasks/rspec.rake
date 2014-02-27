if Rails.env=='ci'
  require 'rspec/core/rake_task'

  namespace :spec do

    desc 'Run tests depending on the TEST_SUITE env variable: "unit"=>unit tests, "acceptance"=>acceptance tests'
    RSpec::Core::RakeTask.new(:travisci) do |task|
      all_tests = FileList['spec/**/*_spec.rb']
      unit_tests = FileList['spec/**/*_spec.rb'].exclude 'spec/features/**/*_spec.rb'
      acceptance_tests_1 = FileList['spec/features/feed_subscription_spec.rb',
                                    'spec/features/folders_spec.rb',
                                    'spec/features/import_subscriptions_spec.rb',
                                    'spec/features/quick_reading_spec.rb',
                                    'spec/features/refresh_feed_spec.rb',
                                    'spec/features/start_page_spec.rb',
                                    'spec/features/unread_entries_count_spec.rb']
      acceptance_tests_2 = FileList['spec/features/**/*_spec.rb'].exclude acceptance_tests_1

      if ENV['TEST_SUITE'] == 'unit'
        # Include only unit tests
        file_list = unit_tests
      elsif ENV['TEST_SUITE'] == 'acceptance_1'
        # Include only some feature tests
        file_list = acceptance_tests_1
      elsif ENV['TEST_SUITE'] == 'acceptance_2'
        # Include some feature tests
        file_list = acceptance_tests_2
      else
        # Run all tests
        file_list = all_tests
      end

      task.pattern = file_list
    end

  end
end


