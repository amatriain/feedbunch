# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :refresh_feed_job_status do
    status 'RUNNING'
    user
    feed
  end
end
