# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :data_import do
    status 'NONE'
    total_feeds 256
    processed_feeds 128
    show_alert true
    user
  end
end
