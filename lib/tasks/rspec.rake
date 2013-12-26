namespace :spec do

  desc 'Run tests depending on the TEST_SUITE env variable: "unit"=>unit tests, "acceptance"=>acceptance tests'
  RSpec::Core::RakeTask.new(:travisci) do |task|
    if ENV['TEST_SUITE'] == 'unit'
      # Include only unit tests
      file_list = FileList['spec/**/*_spec.rb']
      file_list = file_list.exclude('spec/features/**/*_spec.rb')
    elsif ENV['TEST_SUITE'] == 'acceptance'
      # Include only feature tests
      file_list = FileList['spec/features/**/*_spec.rb']
    else
      # Run all tests
      file_list = FileList['spec/**/*_spec.rb']
    end

    task.pattern = file_list
  end

end