# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :opml_export_job_state do
    state 'NONE'
    show_alert true
    user
  end
end
