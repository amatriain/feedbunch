# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :opml_import_job_state do
    state 'NONE'
    total_feeds 256
    processed_feeds 128
    show_alert true
    user
  end
end
