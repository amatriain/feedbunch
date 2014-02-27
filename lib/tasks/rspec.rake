if Rails.env=='ci'
  require 'rspec/core/rake_task'

  namespace :spec do

    desc 'Run tests depending on the TEST_SUITE env variable: "unit"=>unit tests, "acceptance"=>acceptance tests'
    RSpec::Core::RakeTask.new(:travisci) do |task|
      all_tests = FileList['spec/**/*_spec.rb']
      unit_tests = FileList['spec/**/*_spec.rb'].exclude 'spec/features/**/*_spec.rb'
      acceptance_tests_1 = FileList['spec/features/suite_1/**/*_spec.rb']
      acceptance_tests_2 = FileList['spec/features/suite_2/**/*_spec.rb']

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


