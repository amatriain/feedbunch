# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :data_import do
    status 'RUNNING'
    total_feeds 256
    processed_feeds 128
    user

    factory :data_import_running do
      status 'RUNNING'
      total_feeds 256
      processed_feeds 128
    end

    factory :data_import_error do
      status 'ERROR'
      total_feeds 256
      processed_feeds 200
    end

    factory :data_import_success do
      status 'SUCCESS'
      total_feeds 256
      processed_feeds 256
    end
  end
end
